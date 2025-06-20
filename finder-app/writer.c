#include <stdio.h>
#include <stdlib.h>
#include <sys/syslog.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
  openlog(NULL, LOG_CONS, LOG_USER);
  if (argc == 3) {
    syslog(LOG_DEBUG, "Writing %s to %s", argv[2], argv[1]);
    FILE *f = fopen(argv[1], "w");
    if (f != NULL) {
      fprintf(f, "%s", argv[2]);
    } else {
      syslog(LOG_ERR, "Can't open the file %s", argv[1]);
      closelog();
      return EXIT_FAILURE;
    }

    fclose(f);

  } else {
    syslog(LOG_ERR, "Invalid number of arguments");
    closelog();
    return EXIT_FAILURE;
  }
  closelog();
  return EXIT_SUCCESS;
}
