#ifndef LINKTOOLS_H
#define LINKTOOLS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Parse MAC address from string
 * @param input Input string (e.g., "00:03:93:12:34:56")
 * @return Formatted MAC address string (must be freed with string_free), or NULL on error
 */
char* mac_parse(const char* input);

/**
 * Lookup vendor name for OUI
 * @param oui_str OUI string (e.g., "000393" or "00:03:93")
 * @return Vendor name string (must be freed with string_free), or NULL if not found
 */
char* oui_lookup(const char* oui_str);

/**
 * Generate a random locally administered MAC address
 * @return Random MAC address string (must be freed with string_free)
 */
char* mac_random_local(void);

/**
 * Generate a random MAC address for a specific vendor
 * @param vendor_id Vendor identifier (e.g., "apple", "cisco")
 * @return Random MAC address string (must be freed with string_free), or NULL if vendor not found
 */
char* mac_random_for_vendor(const char* vendor_id);

/**
 * Anonymize a MAC address (show only prefix)
 * @param mac_str MAC address string
 * @return Anonymized MAC address (e.g., "00:03:93:XX:XX:XX"), must be freed with string_free
 */
char* mac_anonymize(const char* mac_str);

/**
 * Free a string returned from FFI functions
 * @param s String to free
 */
void string_free(char* s);

#ifdef __cplusplus
}
#endif

#endif /* LINKTOOLS_H */
