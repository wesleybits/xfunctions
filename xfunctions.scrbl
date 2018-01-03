#lang scribble/manual

@require[scribble/example
         racket/sandbox]
@require[(for-label racket
                    racket/list
                    racket/date
                    racket/function
                    racket/generator)]
@require[(for-label "main.rkt")]


@(define (make-xfunctions-eval)
   (parameterize ([sandbox-output 'string]
                  [sandbox-error-output 'string]
                  [sandbox-memory-limit 100])
     (make-evaluator 'racket/base
                     #:requires '(racket/list
                                  racket/function
                                  "main.rkt"))))

@defmodule[xfunctions]

@title{XFunctions: Extended Function Combinators}

@author+email["Wesley Bitomski"
              "wesley.bitomski@gmail.com"]

More general-purpose function combinators for you to shake your
programming stick at.  These are largely inspired from Haskell's
arrows implementation for functions. This library implements
reverse composition, with split, join, choose, and guard
operations to help with branching composition and composable
flow control.

Symbolic aliases are provided just so you can confuse and amaze
your friends.

@section{The Operations}

Without much further ado, let's go over the operations.

@defproc[(reverse-apply [value any/c] [function (-> any/c any/c)] ...)
         any/c]{
  @racket[reverse-apply] will apply @racket[value] to @racket[function].
  This is the same as @racket[(function value)].

 If more than one function is applied to @racket[reverse-apply], then
 they are composed in reverse order before being applied to
 @racket[value]. This is (@italic{almost}) the same as
 @racketblock[(foldl (λ (f v) (f v))
                     value
                     (list function ...))]

 This way, the functions are applied in the order that they are listed.}

@defproc[(flip [function (-> any/c any/c any/c)])
         (-> any/c any/c any/c)]{
 @racket[flip] takes a 2-parameter, single-value function, and returns
 that function with the order of its parameters reversed. It is the same
 as @racket[(λ (x y) (function y x))]}

@defproc[(apply-map [value any/c] [functions (listof (-> any/c any/c))] ...)
         (listof any/c)]{
 @racket[apply-map] will apply each function in @racket[functions]
 to @racket[value], returning a list of results. It's the same as
 @racket[(map (λ (f) (f value)) functions)].

 If more than one function list is given, then they are pairwise
 composed across their lists in reverse order. This is the same as
 @racketblock[(map (curry reverse-apply value)
                   function-list1
                   function-list2
                   ...)]}

@defproc[(apply-list [value-list (listof any/c)]
                     [functions (listof (-> any/c any/c))] ...)
         (listof any/c)]{
 @racket[apply-list] will pairwise apply each element in
 @racket[value-list] with each function in @racket[functions]. If more
 than one function list is applied to @racket[apply-list], then those
 function lists are pairwise composed in reverse order, much like
 @racket[apply-map].

 Both forms are the same as @racket[(map reverse-apply value-list functions ...)].}

@defproc*[([(reverse-compose [function (-> any/c any/c)] ...)
            (-> any/c any/c)]
           [(>>> [function (-> any/c any/c)] ...)
            (-> any/c any/c)])]{
 @racket[reverse-compose] composes functions in reverse-order. In other
 words, it composes functions in such a way that they are applied in the
 order that they are listed, or the reverse of @racket[compose].

 It is the same as @racket[(λ (x) (reverse-apply x function ...))].

 @racket[reverse-compose] is aliased by the @racket[>>>] operator.}

@defproc[(<<< [function (-> any/c any/c)] ...)
         (-> any/c any/c)]{
 @racket[<<<] is supplied as an alias for @racket[compose], and behaves
 in the same way.}

@defproc[(split [function (-> any/c any/c)] ...)
         (-> any/c (listof any/c))]{
 @racket[split] will produce a function that receives one value and
 applies it to all of it's parameter functions, collecting the
 results into a list. It is the same as
 @racket[(λ (x) (apply-map x (list function ...)))].}

@defproc[(join [split-functions (-> any/c (listof any/c))]
               [function (-> any/c ... any/c)])
         (-> any/c any/c)]{
 @racket[join] will join a funciton that returns a list of values
 to a function that consumes the list-length number of parameters,
 and is specifically useful for keeping compositions using
 @racket[split] under control.

 It is identical to
 @racket[(λ (x) (apply function (split-functions x)))].}

@defproc[(choose [predicate (-> any/c boolean?)]
                 [then-apply (-> any/c any/c)]
                 [else-apply (-> any/c any/c)])
         (-> any/c any/c)]{
 @racket[choose] generalizes simple composable flow control. It produces
 a unary function that applies it's parameter to either @racket[then-apply]
 or @racket[else-apply] depending on the value returned by
 @racket[predicate] when applied to that one parameter.

 If @racket[predicate] is not false, then @racket[then-apply] is used,
 otherwise @racket[else-apply] is.

 This is the same as
 @racketblock[(λ (x)
                (if (predicate x)
                    (then-apply x)
                    (else-apply x)))]}

@defform[#:literals (else)
         (guard
          [predicate procedure] ...
          [else procedure])
         #:contracts ([predicate (-> any/c boolean?)]
                      [procedure (-> any/c any/c)])]{
 @racket[guard] is to @racket[choose] as @racket[cond] is to @racket[if].
 @racket[guard] will compose nested @racket[choose] applications, much in
 the same way as @racket[cond] composes nested @racket[if] forms. The major
 difference between these two is that @racket[guard] will produce a composed
 function with a minimal grammar, while @racket[cond] is basic execution
 control with support for sanitary anaphora.

 Also with @racket[guard], the @racket[else] clause is manditory, where it's
 not with @racket[cond].

 For example, this @racket[guard]
 @racketblock[(guard [positive? identity]
                     [negative? -]
                     [else (const 0)])]
 will expand to
 @racketblock[(choose positive? identity
                      (choose negative? -
                              (const 0)))]
 and both are implementations for an @racket[abs] function.}
