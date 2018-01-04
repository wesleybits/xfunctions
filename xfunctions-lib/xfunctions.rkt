#lang racket

(module+ test
  (require rackunit))

(define (reverse-apply arg . fns)
  (foldl (λ (f v) (f v))
         arg
         fns))

(define ((flip fn) a b)
  (fn b a))

(define (apply-map arg . fns-lists)
  (apply map (curry reverse-apply arg) fns-lists))

(define (apply-list args . fns-lists)
  (apply map reverse-apply args fns-lists))

(define ((reverse-compose fn . fns) arg)
  (apply reverse-apply arg (cons fn fns)))

(define (split fn . fns)
  (curry (flip apply-map) (cons fn fns)))

(define ((join split-fns joiner-fn) arg)
  (apply joiner-fn (split-fns arg)))

(define ((choose predicate then-app else-app) arg)
  (if (predicate arg)
      (then-app arg)
      (else-app arg)))

(define-syntax (guard stx)
  (syntax-case stx (else)
    [(_ [else else-procedure])
     #'else-procedure]
    [(_ [predicate? procedure] rst ...)
     #'(choose predicate? procedure (guard rst ...))]))

(define >>> reverse-compose)
(define <<< compose)

(provide guard
         (contract-out
          [reverse-apply (->* (any/c) #:rest (listof (-> any/c any/c))
                              any/c)]
          [flip (-> (-> any/c any/c any/c)
                    (-> any/c any/c any/c))]
          [apply-map (-> any/c
                         (listof (-> any/c any/c))
                         any/c)]
          [apply-list (->i ([vals (listof any/c)]
                            [funs (vals)
                                  (and/c (listof (-> any/c any/c))
                                         (λ (funs)
                                           (= (length funs)
                                              (length vals))))])
                           [results (listof any/c)])]
          [reverse-compose (->* ((-> any/c any/c)) #:rest (listof (-> any/c any/c))
                                (-> any/c any/c))]
          [split (->* ((-> any/c any/c)) #:rest (listof (-> any/c any/c))
                      (-> any/c (listof any/c)))]

          [join (-> (-> any/c (listof any/c))
                    procedure?
                    (-> any/c any/c))]
          [choose (-> (-> any/c boolean?)
                      (-> any/c any/c)
                      (-> any/c any/c)
                      (-> any/c any/c))]

          [>>> (->* ((-> any/c any/c)) #:rest (listof (-> any/c any/c))
                    (-> any/c any/c))]
          [<<< (->* ((-> any/c any/c)) #:rest (listof (-> any/c any/c))
                    (-> any/c any/c))]))

(module+ test
  (test-case "flip reverses the order of 2-parameter functions"
    (check-equal? ((flip list) 1 2)
                  (list 2 1)))

  (test-case "reverse-apply applies an argument to a function"
    (check-equal? (reverse-apply 1 list)
                  (list 1)))

  (test-case "apply-map applies an argument to a list of functions"
    (let ([raiser (curry (flip expt))])
      (check-equal? (apply-map 2 (list (raiser 2)
                                       (raiser 3)
                                       (raiser 4)
                                       (raiser 5)))
                    (list 4 8 16 32))))

  (test-case "apply-list applies a list of values pair-wise to a list of functions"
    (check-equal? (apply-list (list 1 2 3 4)
                              (list (curry * 1)
                                    (curry * 2)
                                    (curry * 3)
                                    (curry * 4)))
                  (list 1 4 9 16)))

  (test-case "reverse-compose is the reverse of compose"
    (check-= ((>>> (curry + 2)
                   (curry * 2)
                   (curry - 2))
              4)
             (- 2 (* 2 (+ 2 4)))
             0)
    (check-= ((<<< (curry + 2)
                   (curry * 2)
                   (curry - 2))
              4)
             (+ 2 (* 2 (- 2 4)))
             0)
    (check (negate =)
           ((>>> (curry + 2)
                 (curry * 2)
                 (curry - 2))
            4)
           ((<<< (curry + 2)
                 (curry * 2)
                 (curry - 2))
            4)))

  ;; split
  (test-case "split will apply an argument to a list of functions, giving a list of results"
    (check-equal? ((split (curry + 2)
                          (curry * 2)
                          (curry - 2))
                   4)
                  (list 6 8 -2)))

  ;; join
  (test-case "join will apply a function to a list of values"
    (check-= ((join (split (curry * 4)
                           (curry * 8)
                           (curry * 2))
                    *)
              2)
             (* 8 16 4)
             0))

  (test-case "choose will apply one of two functions based on the result of a predicate"
    (check-= ((choose even? sqr sqrt) 4)
             16
             0)
    (check-= ((choose even? sqr sqrt) 25)
             5
             0)))
