#!/usr/bin/guile -s
!#

(use-modules (ice-9 rdelim))

(define backlight-brightness
  (open-file "/sys/class/backlight/acpi_video0/brightness" "r+"
             #:encoding "US-ASCII"))

(let ((current (string->number (read-line backlight-brightness))))
  (display (+ current (string->number (cadr (command-line))))
           backlight-brightness))
