%include <std_shared_ptr.i>

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
  }
}

%define %_const_nn_shared_ptr(CONST, TYPE)

/*
 * This is copied almost verbatim from std_shared_ptr.i
 * An nn_shared_ptr is almost a shared_ptr except that construction requires i_promise_i_checked_for_null
 * (it is a deliberate PITA)
 */

%typemap(in, fragment="SWIG_null_deleter") dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> {
  TYPE *plain_ptr;
  int res = SWIG_ConvertPtr($input, reinterpret_cast<void**>(&plain_ptr), $descriptor(TYPE *), %convertptr_flags);
  if (!SWIG_IsOK(res)) {
    %argument_fail(res, #TYPE, $symname, $argnum);
  }
  if (!plain_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    std::shared_ptr<CONST TYPE>(plain_ptr, SWIG_null_deleter())
  );
}

%typemap(in, fragment="SWIG_null_deleter")
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & {
  TYPE *plain_ptr;
  int res = SWIG_ConvertPtr($input, reinterpret_cast<void**>(&plain_ptr), $descriptor(TYPE *), %convertptr_flags);
  if (!SWIG_IsOK(res)) {
    %argument_fail(res, #TYPE, $symname, $argnum);
  }
  if (!plain_ptr) {
    %argument_fail(SWIG_TypeError, #TYPE " must not be null", $symname, $argnum);
  }
  $1 = new dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>(
    dropbox::oxygen::i_promise_i_checked_for_null,
    std::shared_ptr<CONST TYPE>(plain_ptr, SWIG_null_deleter())
  );
}
%typemap(freearg)
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> *,
    dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & {
  delete $1;
}

%typemap(out) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> {
  %set_output(SWIG_NewPointerObj(const_cast<TYPE *>($1.get()), $descriptor(TYPE *), SWIG_POINTER_OWN | %newpointer_flags));
  auto *owner = new std::shared_ptr<CONST TYPE>(*&$1);
  auto finalizer = new SWIG_NAPI_Finalizer([owner](){
    delete owner;
  });
  SWIG_NAPI_SetFinalizer(env, $result, finalizer);
}

%typemap(out) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> & {
  %set_output(SWIG_NewPointerObj(const_cast<TYPE *>($1->get()), $descriptor(TYPE *), $owner | %newpointer_flags));
  auto owner = new std::shared_ptr<CONST TYPE>(*$1);
  auto finalizer = new SWIG_NAPI_Finalizer([owner](){
    delete owner;
  });
  SWIG_NAPI_SetFinalizer(env, $result, finalizer);
}

%typemap(in, numinputs=0) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> &OUTPUT {
  $1 = new dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>>;
}
%typemap(argout) sdropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> &OUTPUT {
  %set_output(SWIG_NewPointerObj(const_cast<TYPE *>($1->get()), $descriptor(TYPE *), SWIG_POINTER_OWN | %newpointer_flags));
  auto owner = new std::shared_ptr<CONST TYPE>(*$1);
  auto finalizer = new SWIG_NAPI_Finalizer([owner](){
    delete owner;
  });
  SWIG_NAPI_SetFinalizer(env, $result, finalizer);
}
%typemap(freearg) dropbox::oxygen::nn<std::shared_ptr<CONST TYPE>> &OUTPUT {
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

%define %nn_shared_ptr(TYPE)
%_const_nn_shared_ptr(, TYPE);
%_const_nn_shared_ptr(const, TYPE);
%shared_ptr(TYPE);
%apply std::shared_ptr<TYPE> & { std::shared_ptr<TYPE> const & };
%enddef
