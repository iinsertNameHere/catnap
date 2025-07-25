#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/statvfs.h>
#define GB 1073741824

// Get all mounting points
const char* getMountPoints() {
    FILE* mounts = fopen("/proc/mounts", "r");
    if (!mounts) {
        return "";
    }

    char line[256];
    char mountPoint[256];
    char device[256];
    char fsType[256];
    char result[4096] = ""; // Assuming max result size
    while (fgets(line, sizeof(line), mounts)) {
        sscanf(line, "%s %s %s", device, mountPoint, fsType);
        strcat(result, mountPoint);
        strcat(result, ",");
    }

    fclose(mounts);

    char* resultPtr = strdup(result);
    return resultPtr;
}

double getTotalDiskSpace(const char* mountingPoint) {
    struct statvfs buffer;
    if (statvfs(mountingPoint, &buffer) != 0) return -1.f;
    const double total = (double)(buffer.f_blocks * buffer.f_frsize) / GB;
    return total;
}

double getUsedDiskSpace(const char* mountingPoint) {
    struct statvfs buffer;
    if (statvfs(mountingPoint, &buffer) != 0) return -1.f;;
    const double total = (double)(buffer.f_blocks * buffer.f_frsize) / GB;
    const double available = (double)(buffer.f_bfree * buffer.f_frsize) / GB;
    const double used = total - available;
    return used;
}

