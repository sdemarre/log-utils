;;;; log-utils.asd

(asdf:defsystem #:log-utils
  :description "Describe log-utils here"
  :author "Your Name <your.name@example.com>"
  :license "Specify license here"
  :serial t
  :depends-on (:iterate :alexandria :cl-ppcre :split-sequence)
  :components ((:file "package")
               (:file "log-utils")))

