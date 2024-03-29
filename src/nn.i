%include <std_shared_ptr.i>
%include <std_unique_ptr.i>

/*
 * SWIG implementation of dropbox::oxygen::nn pointers.
 *
 * This is language-independent and should work for languages other than JavaScript.
 * The low-level work is delegated to the corresponding shared_ptr and unique_ptr
 * language-specific typemaps.
 *
 * The public interface macros are at the end.
 */

/*
 * Tell SWIG about nn - everything it needs to know is that it is a non-default-constructible class
 * (the nn.hpp file cannot be included as it contains a trigger for a SWIG parser bug:
 * https://github.com/swig/swig/issues/2228)
 */
namespace dropbox {
  namespace oxygen {
    template <typename PtrType> class nn {
      public:
        nn() = delete;
    };
    using i_promise_i_checked_for_null = void;
    using nn_dynamic_pointer_cast = void;
    using nn_make_shared = void;
    using nn_static_pointer_cast = void;
  }
}

%define %_const_nn_shared_ptr(CONST, TYPE)

/*
 * Most typemaps are identical to those from std_shared_ptr.i
 * An nn_shared_ptr is almost a shared_ptr except that construction requires i_promise_i_checked_for_null
 * (it is a deliberate PITA)
 */
%apply std::shared_ptr<CONST TYPE>    { dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> };
%apply std::shared_ptr<CONST TYPE> &  { dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & };
%apply std::shared_ptr<CONST TYPE> *  { dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> * };

%typemap(in) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> {
  std::shared_ptr<CONST TYPE> shared_ptr;
  $typemap(in, std::shared_ptr<CONST TYPE>, 1=shared_ptr);
  if (!shared_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    shared_ptr
  );
}

%typemap(in)
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & {
  std::shared_ptr<CONST TYPE> shared_ptr;
  $typemap(in, std::shared_ptr<CONST TYPE>, 1=shared_ptr);
  if (!shared_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = new dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    shared_ptr
  );
}
%typemap(freearg)
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & {
  delete $1;
}

%template() dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>;

#ifdef SWIGTYPESCRIPT
%typemap(ts) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>, dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> &
    "$typemap(ts, " #TYPE ")"
%typemap(tsout) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> &OUTPUT
    "$typemap(ts, " #TYPE ")"
#endif

%enddef

%define %_const_nn_unique_ptr(CONST, TYPE)

%apply std::unique_ptr<CONST TYPE>    { dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> };
%apply std::unique_ptr<CONST TYPE> &  { dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> & };
%apply std::unique_ptr<CONST TYPE> && { dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> && };
%apply std::unique_ptr<CONST TYPE> *  { dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> * };

%typemap(in) dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> {
  std::unique_ptr<CONST TYPE> unique_ptr;
  $typemap(in, std::unique_ptr<CONST TYPE>, 1=unique_ptr);
  if (!unique_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    std::move(unique_ptr)
  );
}

%typemap(in)
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> &,
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> && {
  std::unique_ptr<CONST TYPE> unique_ptr;
  $typemap(in, std::unique_ptr<CONST TYPE>, 1=unique_ptr);
  if (!unique_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = new dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    std::move(unique_ptr)
  );
}
%typemap(freearg)
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> &,
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> && {
  delete $1;
}

// nn pointers do not allow a direct release, they must
// be move-cast to std::unique_ptr
%typemap(out) dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> {
  std::unique_ptr<CONST TYPE> unique_ptr((std::unique_ptr<CONST TYPE> &&)((&$1)->as_nullable()));
  %set_output(SWIG_NewPointerObj(unique_ptr.release(), $descriptor(TYPE *), SWIG_POINTER_OWN | %newpointer_flags));
}

%typemap(out)
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> &,
    dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> && {
  %set_output(SWIG_NewPointerObj($1->get(), $descriptor(TYPE *), $owner | %newpointer_flags));
}

%template() dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>>;

#ifdef SWIGTYPESCRIPT
%typemap(ts) dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>>, dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> &
    "$typemap(ts, " #TYPE ")"
%typemap(tsout) dropbox::oxygen::nn<std::unique_ptr<CONST TYPE>> &OUTPUT
    "$typemap(ts, " #TYPE ")"
#endif

%enddef

/*
 * This is the public interface macros
 */

%define %nn_shared_ptr(TYPE)
%shared_ptr(TYPE);
%_const_nn_shared_ptr(, TYPE);
%_const_nn_shared_ptr(const, TYPE);
%enddef

%define %nn_unique_ptr(TYPE)
%unique_ptr(TYPE);
%_const_nn_unique_ptr(, TYPE);
%enddef
