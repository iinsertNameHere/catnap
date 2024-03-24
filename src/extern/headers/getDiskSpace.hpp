#define GB 1073741824

#ifdef __linux__ 
#include <sys/statvfs.h>

double getTotalDiskSpace() {
    struct statvfs buffer;
    statvfs("/", &buffer);
    const double total = (double)(buffer.f_blocks * buffer.f_frsize) / GB;
    return total;
}

double getUsedDiskSpace() {
    struct statvfs buffer;
    statvfs("/", &buffer);
    const double total = (double)(buffer.f_blocks * buffer.f_frsize) / GB;
    const double available = (double)(buffer.f_bfree * buffer.f_frsize) / GB;
    const double used = total - available;
    return used;
}

#else
#include <Windows.h>

double getTotalDiskSpace() {
    ULARGE_INTEGER totalSize, freeSize, totalFreeSize;
    GetDiskFreeSpaceEx(NULL, &freeSize, &totalSize, &totalFreeSize)
    return (double)totalSize.QuadPart / GB;
}

double getUsedDiskSpace() {
    ULARGE_INTEGER totalSize, freeSize, totalFreeSize;
    GetDiskFreeSpaceEx(NULL, &freeSize, &totalSize, &totalFreeSize)
    return (double)(totalSize.QuadPart - freeSize.QuadPart) / GB;
}

#endif