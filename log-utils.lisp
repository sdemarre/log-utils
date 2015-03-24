;;;; log-utils.lisp

(in-package #:log-utils)

;;; "log-utils" goes here. Hacks and glory await!


(defun file-lines (filename)
  (iter (for line in-file filename using #'read-line)
	(collect line)))

(defun clean-log-file (log-file-name)
  "removes trailing newlines, tabs and spaces"
  (iter (for line in-file log-file-name using #'read-line)
	(collect (cl-ppcre:regex-replace " +$" (cl-ppcre:regex-replace-all "\\t" (remove #\Return line) " ") ""))))

(defun save-lines (lines filename)
  (with-open-file (s filename :direction :output :if-exists :supersede)
    (format s "~{~a~%~}" lines)))

(defun line-matches-p (rx line)
  (cl-ppcre:scan rx line))

(defun lines-matching (lines rx)
  (iter (for line in lines)
	(when (line-matches-p rx line)
	  (collect line))))

(defun lines-matching-any (lines any-rx)
  (iter (for line in lines)
	(when (iter (for rx in any-rx)
		    (thereis (line-matches-p rx line)))
	  (collect line))))

(defun lines-not-matching (lines rx)
  (iter (for line in lines)
	(when (not (line-matches-p rx line))
	  (collect line))))

(defun entry-return-lines (lines)
  (lines-matching-any lines '(": entry" ": return")))

(defun line-symbol (line)
  (fourth (cl-ppcre:split " +" line)))

(defun line-thread (line)
  (fourth (cl-ppcre:split "#+" (line-symbol line))))

(defun fix-template-identifiers (lines)
  (iter (for line in lines)
	(collect (cl-ppcre:regex-replace "class " line "class_"))))

(defun check-entry-return (lines)
  (let ((stack-hash (make-hash-table :test #'equal)))
    (iter (for line in lines)
	  (for linum from 1)
	  (let ((thread (line-thread line))
		(symbol (line-symbol line)))
	    (cond ((cl-ppcre:scan ": entry" line) (push symbol (gethash thread stack-hash)))
		  ((cl-ppcre:scan ": return" line) (if (or (null (gethash thread stack-hash))
							   (string= symbol (car (gethash thread stack-hash))))
						       (pop (gethash thread stack-hash))
						       (collect (format nil "no match found for ~a at ~a" symbol linum)))))))))


(defun create-entry-return-report (log-filename report-name)
  (with-open-file (s report-name :direction :output :if-exists :supersede)
    (format s "~{~s~%~}"(check-entry-return (fix-template-identifiers (clean-log-file log-filename))))))
