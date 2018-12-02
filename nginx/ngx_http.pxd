from .nginx_core cimport ngx_module_t, ngx_log_t


cdef extern from "ngx_http.h":
    ctypedef struct ngx_connection_t:
        ngx_log_t *log

    ctypedef struct ngx_http_request_t:
        ngx_connection_t *connection

    void ngx_http_core_run_phases(ngx_http_request_t *request)
    void *ngx_http_get_module_ctx(ngx_http_request_t *request,
                                  ngx_module_t module)
    void ngx_http_set_ctx(ngx_http_request_t *request, void *ctx,
                          ngx_module_t module)
