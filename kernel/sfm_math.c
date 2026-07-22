/* SFM layout arithmetic, compiled by Byte-found.
   Keeping these numbers in one place instead of scattered
   through the assembly sources. */

int sfm_superblock_lba() {
    return 40;
}

int sfm_dir_lba() {
    return 41;
}

/* Each file gets a fixed run of 8 sectors after the directory. */
int sfm_data_lba(int index) {
    return 42 + index * 8;
}

/* Directory entries are 32 bytes each. */
int sfm_dir_entry_offset(int index) {
    return index * 32;
}

/* "SFM1" read back as two little-endian words. */
int sfm_magic_ok(int word0, int word1) {
    if (word0 != 18003) {
        return 0;
    }
    if (word1 != 12621) {
        return 0;
    }
    return 1;
}
