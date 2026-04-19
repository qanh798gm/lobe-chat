@echo off
REM LobeChat Backup Script for Windows
REM Run via Task Scheduler for automated daily/weekly backups

setlocal EnableDelayedExpansion

REM === CONFIGURATION ===
set BACKUP_DIR=%~dp0backups
set DB_CONTAINER=lobe-postgres
set RUSTFS_VOLUME=lobehub_rustfs-data
set REDIS_VOLUME=lobehub_redis_data
set DB_NAME=lobechat
set KEEP_DAILY=7
set KEEP_WEEKLY=4

REM === DATE STAMP ===
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set DATESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%
set TIMESTAMP=%datetime:~0,4%%datetime:~4,2%%datetime:~6,2%_%datetime:~8,2%%datetime:~10,2%

echo [%DATESTAMP%] Starting LobeChat backup...

REM === CREATE BACKUP DIRECTORIES ===
if not exist "%BACKUP_DIR%\db" mkdir "%BACKUP_DIR%\db"
if not exist "%BACKUP_DIR%\s3" mkdir "%BACKUP_DIR%\s3"
if not exist "%BACKUP_DIR%\config" mkdir "%BACKUP_DIR%\config"

REM === 1. BACKUP POSTGRESQL (pg_dump) ===
echo [%DATESTAMP%] Backing up PostgreSQL...
set DB_BACKUP=%BACKUP_DIR%\db\lobechat_%TIMESTAMP%.sql
docker exec %DB_CONTAINER% pg_dump -U postgres %DB_NAME% > "%DB_BACKUP%"
if %ERRORLEVEL% equ 0 (
    echo [%DATESTAMP%] PostgreSQL backup saved: %DB_BACKUP%
) else (
    echo [%DATESTAMP%] ERROR: PostgreSQL backup failed!
    exit /b 1
)

REM === 2. BACKUP RUSTFS (S3 files) ===
echo [%DATESTAMP%] Backing up RustFS volume...
set S3_BACKUP=%BACKUP_DIR%\s3\rustfs_%TIMESTAMP%.tar
docker run --rm -v %RUSTFS_VOLUME%:/data -v "%BACKUP_DIR%\s3":/backup alpine tar cf /backup/rustfs_%TIMESTAMP%.tar -C /data .
if %ERRORLEVEL% equ 0 (
    echo [%DATESTAMP%] RustFS backup saved: %S3_BACKUP%
) else (
    echo [%DATESTAMP%] WARNING: RustFS backup failed (non-critical if no uploads)
)

REM === 3. BACKUP CONFIG FILES ===
echo [%DATESTAMP%] Backing up config files...
copy "%~dp0.env" "%BACKUP_DIR%\config\.env_%TIMESTAMP%.bak" >nul 2>&1
echo [%DATESTAMP%] Config backup done.

REM === 4. CLEANUP OLD DAILY BACKUPS (keep last N) ===
echo [%DATESTAMP%] Cleaning up old backups...
set COUNT=0
for /f "delims=" %%F in ('dir /b /o-d "%BACKUP_DIR%\db\lobechat_*.sql" 2^>nul') do (
    set /a COUNT+=1
    if !COUNT! gtr %KEEP_DAILY% (
        del "%BACKUP_DIR%\db\%%F"
        echo [%DATESTAMP%] Deleted old backup: %%F
    )
)
set COUNT=0
for /f "delims=" %%F in ('dir /b /o-d "%BACKUP_DIR%\s3\rustfs_*.tar" 2^>nul') do (
    set /a COUNT+=1
    if !COUNT! gtr %KEEP_DAILY% (
        del "%BACKUP_DIR%\s3\%%F"
        echo [%DATESTAMP%] Deleted old S3 backup: %%F
    )
)

echo [%DATESTAMP%] Backup complete!
echo Backups stored in: %BACKUP_DIR%
