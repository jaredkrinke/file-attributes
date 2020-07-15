#|
 This file is a part of file-attributes
 (c) 2020 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.file-attributes)

;; Scrubbed from Linux AMD64
(cffi:defcstruct (stat :size 144)
  (mode  :uint32 :offset 24)
  (uid   :uint32 :offset 28)
  (gid   :uint32 :offset 32)
  (size  :uint64 :offset 48)
  (atime :uint64 :offset 72)
  (mtime :uint64 :offset 88))

(cffi:defcfun (cstat "stat") :int
  (path :string)
  (buffer :pointer))

(cffi:defcfun (cutimes "utimes") :int
  (path :string)
  (times :pointer))

(cffi:defcfun (cchown "chown") :int
  (path :string)
  (owner :uint32)
  (group :uint32))

(cffi:defcfun (cchmod "chmod") :int
  (path :string)
  (mode :uint32))

(defun enpath (path)
  (etypecase path
    (string path)
    (stream (namestring (pathname path)))
    (pathname (namestring path))))

(defun stat (path)
  (cffi:with-foreign-object (ptr '(:struct stat))
    (if (= 0 (cstat (enpath path) ptr))
        (cffi:mem-ref ptr '(:struct stat))
        (error "Stat failed."))))

(defun utimes (path atime mtime)
  (cffi:with-foreign-object (ptr :long 4)
    (setf (cffi:mem-aref ptr :long 0) (universal->unix atime))
    (setf (cffi:mem-aref ptr :long 2) (universal->unix mtime))
    (unless (= 0 (cutimes (enpath path) ptr))
      (error "Utimes failed."))))

(defun chown (path uid gid)
  (cchown (enpath path) uid gid))

(defun chmod (path mode)
  (cchmod (enpath path) mode))

(defun unix->universal (unix)
  (+ unix (encode-universal-time 0 0 0 1 1 1970 0)))

(defun universal->unix (universal)
  (- universal (encode-universal-time 0 0 0 1 1 1970 0)))

(define-implementation access-time (file)
  (unix->universal (getf (stat file) 'atime)))

(define-implementation (setf access-time) (value file)
  (utimes file value (modification-time file))
  value)

(define-implementation modification-time (file)
  (unix->universal (getf (stat file) 'mtime)))

(define-implementation (setf modification-time) (value file)
  (utimes file (access-time file) value)
  value)

(define-implementation creation-time (file)
  )

(define-implementation (setf creation-time) (value file)
  )

(define-implementation group (file)
  (getf (stat file) :gid))

(define-implementation (setf group) (value file)
  (chown file (owner file) value)
  value)

(define-implementation owner (file)
  (getf (stat file) :uid))

(define-implementation (setf owner) (value file)
  (chown file value (group file))
  value)

(define-implementation permissions (file)
  (getf (stat file) :mode))

(define-implementation (setf permissions) (value file)
  (chmod file value))
