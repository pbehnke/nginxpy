# cython: language_level=3

import traceback
from enum import IntEnum

from .nginx_config cimport ngx_int_t
from .nginx_core cimport ngx_module_t, ngx_cycle_t
from .nginx_core cimport NGX_OK, NGX_ERROR, NGX_DECLINED, NGX_AGAIN
from .nginx_core cimport NGX_LOG_DEBUG, NGX_LOG_CRIT
from .nginx_core cimport ngx_log_error
from .nginx_core cimport ngx_chain_t, ngx_str_t
from .nginx_event cimport ngx_event_handler_pt


cdef extern from "ngx_python_module.h":
    ngx_module_t ngx_python_module
    ctypedef struct ngx_http_python_loc_conf_t:
        int is_wsgi
        ngx_str_t asgi_pass
        int version

    ctypedef struct ngx_http_python_main_conf_t:
        ngx_str_t executor_conf

    ngx_int_t ngx_python_notify(ngx_event_handler_pt evt_handler)


class ReturnCode(IntEnum):
    ok = NGX_OK
    error = NGX_ERROR
    declined = NGX_DECLINED
    again = NGX_AGAIN


cdef public ngx_int_t nginxpy_init_process(ngx_cycle_t *cycle) with gil:
    ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                  b'Starting init_process.')
    # noinspection PyBroadException
    try:
        from . import hooks
        global current_cycle
        current_cycle = Cycle.from_ptr(cycle)
        set_last_resort(current_cycle.log)
        hooks.init_process()
    except:
        ngx_log_error(NGX_LOG_CRIT, cycle.log, 0,
                      b'Error occured in init_process:\n' +
                      traceback.format_exc().encode())
        return NGX_ERROR
    else:
        ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                      b'Finished init_process.')
        return NGX_OK


cdef public void nginxpy_exit_process(ngx_cycle_t *cycle) with gil:
    ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                  b'Starting exit_process.')
    # noinspection PyBroadException
    try:
        from . import hooks
        global current_cycle
        hooks.exit_process()
        unset_last_resort()
        current_cycle = None
    except:
        ngx_log_error(NGX_LOG_CRIT, cycle.log, 0,
                      b'Error occured in exit_process:\n' +
                      traceback.format_exc().encode())
    else:
        ngx_log_error(NGX_LOG_DEBUG, cycle.log, 0,
                      b'Finished exit_process.')


include "log.pyx"
include "cycle.pyx"
include "http/http.pyx"
include "asyncio/loop.pyx"
include "asgi/asgi.pyx"
