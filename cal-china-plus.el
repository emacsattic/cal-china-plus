;;; cal-china-plus.el --- extra stuff for cal-china

;; Copyright (C) 2008  Leo Shidai Liu

;; Author: Leo Shidai Liu <shidai.liu@gmail.com>
;; Keywords: calendar, convenience, local

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; All functions are prefixed with calendar-chinese- unless it is
;; already in cal-china.el; in this case, it is prefixed with
;; calendar-chinese-plus-

;; *NB*: the Chinese calendar date is represented with '(month day
;; nl-year) instead of '(cycle year month day) in the dary file, where
;; nl-year is Nong-Li year offset by constant 2697. For example, Cycle
;; 78 Year 25 is Nong-Li year 4705 but for convenience it is
;; represented as 2008 (i.e. 4705 - 2697) in the diary file.

;; Please send me any comments that you may have. Thank you.

;;; Code:

(require 'cal-china)
(require 'diary-lib)

;;; modification to existing variables and functions
(setq calendar-chinese-celestial-stem
      ["��" "��" "��" "��" "��" "��" "��" "��" "��" "��"])
(setq calendar-chinese-terrestrial-branch
      ["��" "��" "��" "î" "��" "��" "��" "δ" "��" "��" "��" "��"])
(defun calendar-chinese-sexagesimal-name (n)
  "The N-th name of the Chinese sexagesimal cycle.
N congruent to 1 gives the first name, N congruent to 2 gives the second name,
..., N congruent to 60 gives the sixtieth name."
  ;; "%s-%s" -> "%s%s", since Chinese characters are tight one by one,
  ;; no extra `-' needed.
  (format "%s%s"
          (aref calendar-chinese-celestial-stem (% (1- n) 10))
          (aref calendar-chinese-terrestrial-branch (% (1- n) 12))))
;;; end of modification

;; Don't set this to ["1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12"]
(defvar calendar-chinese-month-name-array
  ["һ��" "����" "����" "����" "����" "����"
   "����" "����" "����" "ʮ��" "ʮһ��" "����"])

(defcustom diary-chinese-entry-symbol "C"
  "Symbol indicating a diary entry according to the Chinese calendar."
  :type 'string
  :group 'diary)

;;; nl-year 2008 is NongLi 4705 or Cycle 78 Year 25
;;; Code adapted from `calendar-chinese-to-absolute'
(defun calendar-chinese-year-to-nlyear (cycle year)
  (+ (* (1- cycle) 60)                  ; years in prior cycles
     (1- year)                          ; prior years this cycle
     -2636))

(defun calendar-chinese-year-from-nlyear (nlyear)
  "Return Chinese Cycle and Year for NLYEAR."
  (let ((c-year (+ nlyear 2696)))
    (list (/ c-year 60)
          (1+ (mod c-year 60)))))

(defun calendar-chinese-from-absolute* (date)
  "The returned date is in the form '(month day nlyear)."
  (let* ((c-date (calendar-chinese-from-absolute date))
         (cycle (nth 0 c-date))
         (year (nth 1 c-date))
         ;; handle leap month
         (month (floor (nth 2 c-date)))
         (day (nth 3 c-date))
         (nlyear (calendar-chinese-year-to-nlyear cycle year)))
    (list month day nlyear)))

;; date example: '(month day nlyear)
(defun calendar-chinese-to-absolute* (date)
  (let* ((year (car (last date)))
         (cy (calendar-chinese-year-from-nlyear year))
         (c-date (append cy (list (car date) (cadr date)))))
    (calendar-chinese-to-absolute c-date)))

;;;###autoload
(defun diary-chinese-list-entries ()
  "Add any Chinese date entries from the diary file to `diary-entries-list'.
Chinese date diary entries must be prefaced by `diary-chinese-entry-symbol'
\(normally an `I').  The same `diary-date-forms' govern the style
of the Chinese calendar entries. If an Islamic date diary entry begins with
`diary-nonmarking-symbol', the entry will appear in the diary listing,
but will not be marked in the calendar.
This function is provided for use with `diary-nongregorian-listing-hook'."
  (diary-list-entries-1 calendar-chinese-month-name-array
                        diary-chinese-entry-symbol
                        'calendar-chinese-from-absolute*))

;;; calendar-mark-1 seems only work with islamic and bahai
(defun calendar-chinese-mark-date-pattern (month day year &optional color)
  "Mark dates in calendar window that conform to chinese date MONTH/DAY/YEAR.
A value of 0 in any position is a wildcard.  Optional argument COLOR is
passed to `calendar-mark-visible-date' as MARK."
  (save-excursion
    (set-buffer calendar-buffer)
    (if (and (not (zerop month)) (not (zerop day)))
        (if (not (zerop year))
            ;; Fully specified date.
            (let ((date (calendar-gregorian-from-absolute
                         (calendar-chinese-to-absolute* (list month day year)))))
              (if (calendar-date-is-visible-p date)
                  (calendar-mark-visible-date date color)))
          ;; Month and day in any year.
          (let ((gdate (calendar-nongregorian-visible-p
                        month day 'calendar-chinese-to-absolute*
                        'calendar-chinese-from-absolute*
                        (lambda (m) (< m 6)))))
            (if gdate (calendar-mark-visible-date gdate color))))
      (calendar-mark-complex month day year
                             'calendar-chinese-from-absolute* color))))

;;;###autoload
(defun diary-chinese-mark-entries ()
  "Mark days in the calendar window that have Chinese date diary entries.
Marks each entry in `diary-file' (or included files) visible in the calendar
window.  See `diary-chinese-list-entries' for more information.
This function is provided for use with `diary-nongregorian-marking-hook'."
  (diary-mark-entries-1 'calendar-chinese-mark-date-pattern
                        calendar-chinese-month-name-array
                        diary-chinese-entry-symbol
                        'calendar-chinese-from-absolute*))

;;;###autoload
(defun diary-chinese-insert-entry (arg)
  "Insert a diary entry.
For the Chinese date corresponding to the date indicated by point.
Prefix argument ARG makes the entry nonmarking."
  (interactive "P")
  (diary-insert-entry-1 nil arg calendar-chinese-month-name-array
                        diary-chinese-entry-symbol
                        'calendar-chinese-from-absolute*))

;;;###autoload
(defun diary-chinese-insert-monthly-entry (arg)
  "Insert a monthly diary entry.
For the day of the Chinese month corresponding to the date indicated by point.
Prefix argument ARG makes the entry nonmarking."
  (interactive "P")
  (diary-insert-entry-1 'monthly arg calendar-chinese-month-name-array
                        diary-chinese-entry-symbol
                        'calendar-chinese-from-absolute*))

;;;###autoload
(defun diary-chinese-insert-yearly-entry (arg)
  "Insert an annual diary entry.
For the day of the Chinese year corresponding to the date indicated by point.
Prefix argument ARG makes the entry nonmarking."
  (interactive "P")
  (diary-insert-entry-1 'yearly arg calendar-chinese-month-name-array
                        diary-chinese-entry-symbol
                        'calendar-chinese-from-absolute*))

(defvar date)
(defvar entry)

;;;###autoload
(defun diary-chinese-anniversary (month day &optional year mark)
  "Anniversary diary entry in Chinese MONTH and DAY with gregorian YEAR."
  (let* ((ddate (diary-make-date month day year))
         (dd (calendar-extract-day ddate))
         (mm (calendar-extract-month ddate))
         (yy (calendar-extract-year ddate))
         (a-date (calendar-absolute-from-gregorian date))
         (c-date (calendar-chinese-from-absolute a-date))
         (mm2 (nth 2 c-date))
         (dd2 (nth 3 c-date))
         (y (calendar-extract-year date))
         (diff (if yy (- y yy) 100)))
    (and (> diff 0) (= mm mm2) (= dd dd2)
         (cons mark (format entry diff (diary-ordinal-suffix diff))))))

;;;###autoload
(defun diary-chinese-insert-anniversary-entry (arg)
  "Insert an anniversary diary entry for the Chinese date given by point.
Prefix argument ARG makes the entry nonmarking."
  (interactive "P")
  (let ((calendar-date-display-form (diary-date-display-form)))
    (diary-make-entry
     (format "%s(diary-chinese-anniversary %s)"
             diary-sexp-entry-symbol
             (calendar-date-string
              (calendar-chinese-from-absolute*
               (calendar-absolute-from-gregorian (calendar-cursor-to-date t)))))
     arg)))

(define-key calendar-mode-map "iCa" 'diary-chinese-insert-anniversary-entry)
(define-key calendar-mode-map "iCd" 'diary-chinese-insert-entry)
(define-key calendar-mode-map "iCm" 'diary-chinese-insert-monthly-entry)
(define-key calendar-mode-map "iCy" 'diary-chinese-insert-yearly-entry)

(provide 'cal-china-plus)
;;; cal-china-plus.el ends here
