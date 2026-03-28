/*
 * filedialog_platform.h — Cross-platform file system helpers for QB64-PE
 *
 * Compiled inline by QB64-PE via: DECLARE LIBRARY "filedialog_platform"
 * Provides directory enumeration, file metadata, and system path discovery.
 *
 * Platforms: Windows (Win32 API), Linux (POSIX), macOS (POSIX)
 *
 * (c) 2026 grymmjack — MIT License
 */

#ifndef FILEDIALOG_PLATFORM_H
#define FILEDIALOG_PLATFORM_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN32
    #define WIN32_LEAN_AND_MEAN
    #include <windows.h>
    #include <shlobj.h>
    #include <shlwapi.h>
    #include <sys/types.h>
    #include <sys/stat.h>
    #pragma comment(lib, "shell32.lib")
    #pragma comment(lib, "shlwapi.lib")
#else
    #include <dirent.h>
    #include <sys/stat.h>
    #include <sys/types.h>
    #include <unistd.h>
    #include <pwd.h>
#endif

/* ----------------------------------------------------------------
 * Directory Enumeration
 * ---------------------------------------------------------------- */

/* Opaque directory handle structure */
typedef struct {
#ifdef _WIN32
    HANDLE          hFind;
    WIN32_FIND_DATAA findData;
    int             first;          /* 1 = first entry not yet returned */
    int             done;           /* 1 = no more entries */
#else
    DIR            *dirp;
    char            basePath[1024];
#endif
} fd_dir_handle_t;

/* Pool of directory handles (max 8 simultaneous) */
static fd_dir_handle_t fd_dir_pool[8];
static int fd_dir_pool_used[8] = {0};

/*
 * fd_open_dir — Open a directory for enumeration.
 * Returns slot index (0-7) on success, -1 on failure.
 */
int fd_open_dir(const char *path) {
    int slot = -1;
    for (int i = 0; i < 8; i++) {
        if (!fd_dir_pool_used[i]) { slot = i; break; }
    }
    if (slot < 0) return -1;

#ifdef _WIN32
    char searchPath[1024];
    snprintf(searchPath, sizeof(searchPath), "%s\\*", path);
    fd_dir_pool[slot].hFind = FindFirstFileA(searchPath, &fd_dir_pool[slot].findData);
    if (fd_dir_pool[slot].hFind == INVALID_HANDLE_VALUE) return -1;
    fd_dir_pool[slot].first = 1;
    fd_dir_pool[slot].done = 0;
#else
    fd_dir_pool[slot].dirp = opendir(path);
    if (!fd_dir_pool[slot].dirp) return -1;
    strncpy(fd_dir_pool[slot].basePath, path, sizeof(fd_dir_pool[slot].basePath) - 1);
    fd_dir_pool[slot].basePath[sizeof(fd_dir_pool[slot].basePath) - 1] = '\0';
#endif

    fd_dir_pool_used[slot] = 1;
    return slot;
}

/*
 * fd_read_entry — Read next directory entry name into buf.
 * Returns 1 if an entry was read, 0 if no more entries.
 * Skips "." and ".." automatically.
 */
int fd_read_entry(int slot, char *buf, int buf_len) {
    if (slot < 0 || slot >= 8 || !fd_dir_pool_used[slot]) return 0;
    if (buf_len <= 0) return 0;

#ifdef _WIN32
    fd_dir_handle_t *h = &fd_dir_pool[slot];
    while (1) {
        if (h->done) return 0;
        if (h->first) {
            h->first = 0;
        } else {
            if (!FindNextFileA(h->hFind, &h->findData)) {
                h->done = 1;
                return 0;
            }
        }
        /* Skip . and .. */
        if (strcmp(h->findData.cFileName, ".") == 0) continue;
        if (strcmp(h->findData.cFileName, "..") == 0) continue;
        strncpy(buf, h->findData.cFileName, buf_len - 1);
        buf[buf_len - 1] = '\0';
        return 1;
    }
#else
    struct dirent *ent;
    while ((ent = readdir(fd_dir_pool[slot].dirp)) != NULL) {
        if (strcmp(ent->d_name, ".") == 0) continue;
        if (strcmp(ent->d_name, "..") == 0) continue;
        strncpy(buf, ent->d_name, buf_len - 1);
        buf[buf_len - 1] = '\0';
        return 1;
    }
    return 0;
#endif
}

/*
 * fd_close_dir — Close a directory handle and free the slot.
 */
void fd_close_dir(int slot) {
    if (slot < 0 || slot >= 8 || !fd_dir_pool_used[slot]) return;

#ifdef _WIN32
    if (fd_dir_pool[slot].hFind != INVALID_HANDLE_VALUE) {
        FindClose(fd_dir_pool[slot].hFind);
    }
#else
    if (fd_dir_pool[slot].dirp) {
        closedir(fd_dir_pool[slot].dirp);
        fd_dir_pool[slot].dirp = NULL;
    }
#endif

    fd_dir_pool_used[slot] = 0;
}

/* ----------------------------------------------------------------
 * File Metadata
 * ---------------------------------------------------------------- */

/*
 * fd_is_directory — Returns 1 if path is a directory, 0 otherwise.
 */
int fd_is_directory(const char *path) {
#ifdef _WIN32
    DWORD attr = GetFileAttributesA(path);
    if (attr == INVALID_FILE_ATTRIBUTES) return 0;
    return (attr & FILE_ATTRIBUTE_DIRECTORY) ? 1 : 0;
#else
    struct stat st;
    if (stat(path, &st) != 0) return 0;
    return S_ISDIR(st.st_mode) ? 1 : 0;
#endif
}

/*
 * fd_file_size — Returns file size in bytes, or -1 on error.
 */
long long fd_file_size(const char *path) {
#ifdef _WIN32
    struct __stat64 st;
    if (_stat64(path, &st) != 0) return -1;
    return (long long)st.st_size;
#else
    struct stat st;
    if (stat(path, &st) != 0) return -1;
    return (long long)st.st_size;
#endif
}

/*
 * fd_file_mtime — Returns file modification time as Unix epoch seconds, or 0 on error.
 */
long long fd_file_mtime(const char *path) {
#ifdef _WIN32
    struct __stat64 st;
    if (_stat64(path, &st) != 0) return 0;
    return (long long)st.st_mtime;
#else
    struct stat st;
    if (stat(path, &st) != 0) return 0;
    return (long long)st.st_mtime;
#endif
}

/*
 * fd_is_hidden — Returns 1 if the file/directory is hidden.
 * Linux/macOS: starts with '.'
 * Windows: FILE_ATTRIBUTE_HIDDEN
 */
int fd_is_hidden(const char *path) {
#ifdef _WIN32
    /* Extract filename from path for the attribute check */
    DWORD attr = GetFileAttributesA(path);
    if (attr == INVALID_FILE_ATTRIBUTES) return 0;
    return (attr & FILE_ATTRIBUTE_HIDDEN) ? 1 : 0;
#else
    /* Find the last path component */
    const char *name = strrchr(path, '/');
    if (name) name++; else name = path;
    return (name[0] == '.') ? 1 : 0;
#endif
}

/* ----------------------------------------------------------------
 * System Paths
 * ---------------------------------------------------------------- */

/*
 * fd_home_dir — Write the user's home directory into buf.
 * Returns 1 on success, 0 on failure.
 */
int fd_home_dir(char *buf, int buf_len) {
    if (buf_len <= 0) return 0;
#ifdef _WIN32
    const char *home = getenv("USERPROFILE");
    if (!home) home = getenv("HOMEDRIVE");
    if (!home) { buf[0] = '\0'; return 0; }
    strncpy(buf, home, buf_len - 1);
    buf[buf_len - 1] = '\0';
    return 1;
#else
    const char *home = getenv("HOME");
    if (!home) {
        struct passwd *pw = getpwuid(getuid());
        if (pw) home = pw->pw_dir;
    }
    if (!home) { buf[0] = '\0'; return 0; }
    strncpy(buf, home, buf_len - 1);
    buf[buf_len - 1] = '\0';
    return 1;
#endif
}

/*
 * fd_path_separator — Returns '\\' on Windows, '/' on Unix.
 */
int fd_path_separator(void) {
#ifdef _WIN32
    return '\\';
#else
    return '/';
#endif
}

/*
 * fd_get_xdg_dir — Get standard user directory.
 *   type: 0=Desktop, 1=Documents, 2=Downloads, 3=Pictures, 4=Music, 5=Videos
 * Returns 1 on success, 0 on failure.
 */
int fd_get_xdg_dir(int type, char *buf, int buf_len) {
    if (buf_len <= 0) return 0;
    buf[0] = '\0';

#ifdef _WIN32
    /* Map type to Windows KNOWNFOLDERID */
    const GUID *folderId = NULL;
    switch (type) {
        case 0: folderId = &FOLDERID_Desktop;   break;
        case 1: folderId = &FOLDERID_Documents;  break;
        case 2: folderId = &FOLDERID_Downloads;  break;
        case 3: folderId = &FOLDERID_Pictures;   break;
        case 4: folderId = &FOLDERID_Music;      break;
        case 5: folderId = &FOLDERID_Videos;     break;
        default: return 0;
    }
    PWSTR widePath = NULL;
    if (SUCCEEDED(SHGetKnownFolderPath(folderId, 0, NULL, &widePath))) {
        /* Convert wide string to narrow */
        int len = WideCharToMultiByte(CP_UTF8, 0, widePath, -1, buf, buf_len, NULL, NULL);
        CoTaskMemFree(widePath);
        return (len > 0) ? 1 : 0;
    }
    return 0;
#else
    /* Try XDG user dirs first */
    const char *xdgNames[] = {
        "XDG_DESKTOP_DIR", "XDG_DOCUMENTS_DIR", "XDG_DOWNLOAD_DIR",
        "XDG_PICTURES_DIR", "XDG_MUSIC_DIR", "XDG_VIDEOS_DIR"
    };
    const char *fallbackNames[] = {
        "Desktop", "Documents", "Downloads", "Pictures", "Music", "Videos"
    };

    if (type < 0 || type > 5) return 0;

    /* Check environment variable first */
    const char *envVal = getenv(xdgNames[type]);
    if (envVal && envVal[0]) {
        strncpy(buf, envVal, buf_len - 1);
        buf[buf_len - 1] = '\0';
        return 1;
    }

    /* Parse user-dirs.dirs config file */
    char configPath[512];
    const char *configHome = getenv("XDG_CONFIG_HOME");
    if (configHome && configHome[0]) {
        snprintf(configPath, sizeof(configPath), "%s/user-dirs.dirs", configHome);
    } else {
        char home[256];
        if (!fd_home_dir(home, sizeof(home))) return 0;
        snprintf(configPath, sizeof(configPath), "%s/.config/user-dirs.dirs", home);
    }

    FILE *f = fopen(configPath, "r");
    if (f) {
        char line[512];
        char searchKey[64];
        snprintf(searchKey, sizeof(searchKey), "%s=", xdgNames[type]);
        while (fgets(line, sizeof(line), f)) {
            if (line[0] == '#') continue;
            if (strncmp(line, searchKey, strlen(searchKey)) == 0) {
                char *value = line + strlen(searchKey);
                /* Strip quotes and newlines */
                while (*value == '"' || *value == '\'') value++;
                char *end = value + strlen(value) - 1;
                while (end > value && (*end == '\n' || *end == '\r' || *end == '"' || *end == '\''))
                    *end-- = '\0';

                /* Expand $HOME */
                if (strncmp(value, "$HOME", 5) == 0) {
                    char home[256];
                    if (fd_home_dir(home, sizeof(home))) {
                        snprintf(buf, buf_len, "%s%s", home, value + 5);
                    }
                } else {
                    strncpy(buf, value, buf_len - 1);
                    buf[buf_len - 1] = '\0';
                }
                fclose(f);
                return 1;
            }
        }
        fclose(f);
    }

    /* Fallback: $HOME/<FolderName> */
    char home[256];
    if (fd_home_dir(home, sizeof(home))) {
        snprintf(buf, buf_len, "%s/%s", home, fallbackNames[type]);
        /* Only return success if it actually exists */
        struct stat st;
        if (stat(buf, &st) == 0 && S_ISDIR(st.st_mode)) return 1;
    }

    buf[0] = '\0';
    return 0;
#endif
}

/* ----------------------------------------------------------------
 * Date Formatting Helper
 * ---------------------------------------------------------------- */

/*
 * fd_format_mtime — Format epoch seconds into a human-readable string.
 * Format: "YYYY-MM-DD HH:MM"
 * Returns length of formatted string, or 0 on failure.
 */
int fd_format_mtime(long long epoch, char *buf, int buf_len) {
    if (buf_len < 17) { if (buf_len > 0) buf[0] = '\0'; return 0; }
    time_t t = (time_t)epoch;
    struct tm *tm = localtime(&t);
    if (!tm) { buf[0] = '\0'; return 0; }
    int len = (int)strftime(buf, buf_len, "%Y-%m-%d %H:%M", tm);
    return len;
}

/* ----------------------------------------------------------------
 * Drive / Volume Enumeration (Windows only, stubs for Unix)
 * ---------------------------------------------------------------- */

/*
 * fd_get_drive_count — Returns number of available drive letters (Windows) or 1 (Unix = root).
 */
int fd_get_drive_count(void) {
#ifdef _WIN32
    DWORD drives = GetLogicalDrives();
    int count = 0;
    for (int i = 0; i < 26; i++) {
        if (drives & (1 << i)) count++;
    }
    return count;
#else
    return 1;  /* Unix has just "/" */
#endif
}

/*
 * fd_get_drive — Get the Nth available drive path into buf.
 * Returns 1 on success, 0 on failure.
 */
int fd_get_drive(int index, char *buf, int buf_len) {
    if (buf_len < 4) return 0;
#ifdef _WIN32
    DWORD drives = GetLogicalDrives();
    int count = 0;
    for (int i = 0; i < 26; i++) {
        if (drives & (1 << i)) {
            if (count == index) {
                buf[0] = 'A' + i;
                buf[1] = ':';
                buf[2] = '\\';
                buf[3] = '\0';
                return 1;
            }
            count++;
        }
    }
    return 0;
#else
    if (index == 0) {
        buf[0] = '/';
        buf[1] = '\0';
        return 1;
    }
    return 0;
#endif
}

#endif /* FILEDIALOG_PLATFORM_H */
