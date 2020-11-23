// from https://github.com/KxSystems/prometheus-kdb-exporter
\d .prom

// utils
wraplabels:{$[count x;"{",x,"}";""]}
wrapstring:{"\"",x,"\""}

// schema
metrics:([metric:`$()]metrictype:`$();labelnames:();hdr:())
metricvals:1#([name:`$()]metric:`$();params:();labelhdr:();val:())

// define metric class
newmetric:{[metric;metrictype;labelnames;help]
  hdr:enlist("# HELP ";"# TYPE "),'string[metric],/:" ",'(help;string metrictype);
  metrics,:(metric;metrictype;raze labelnames;hdr);}

// create metric instance
addmetric:{[metric;labelvals;params;startval]
  name:`$"|"sv enlist[string metric],labelvals;
  labelhdr:", "sv string[metrics[metric]`labelnames],'"=",'wrapstring each labelvals;
  metricvals,:(name;metric;params;labelhdr;startval);
  name}

// fetch metric values (specific per metric type)
getval:{[d]enlist wraplabels[d`labelhdr]," ",string d`val}
quantile:{[q;x]r[0]+(p-i 0)*last r:0^deltas asc[x]i:0 1+\:floor p:q*-1+count x}
summary:{[d]
  svals:raze(sum;count;quantile q:d`params)@\:d`val;
  labelhdr:$[count d`labelhdr;enlist d`labelhdr;()];
  hdr:", "sv/:labelhdr,/:(();()),enlist each"quantile=",/:wrapstring each string q;
  hdr:(("_sum";"_count"),count[q]#enlist""),'wraplabels each hdr;
  hdr,'" ",'string svals}
histogram:{[d]
  svals:raze(sum d`val;count d`val;deltas 1+asc[d`val]bin q:d`params);
  labelhdr:$[count d`labelhdr;enlist d`labelhdr;()];
  hdr:", "sv/:labelhdr,/:(();()),enlist each"le=",/:wrapstring each string q;
  hdr:(("_sum";"_count"),count[q]#enlist""),'wraplabels each hdr;
  hdr,'" ",'string svals}

// extract metric info
extractall:{[]
  aggmetrics:exec metric from metrics where metrictype in`summary`histogram;
  metricvals,:select name,asc each val from metricvals where metric in aggmetrics;
  "\n"sv raze extractmetric each 0!metrics}
extractmetric:{[d]
  vals:extractmetricval[d`metrictype]each 0!select from metricvals where metric=d`metric;
  first[d`hdr],raze vals} 
extractmetricval:{[typ;d]
  $[typ=`summary;
     string[d`metric],/:summary d;
    typ=`histogram;
     string[d`metric],/:histogram d;
     string[d`metric],/:getval d
  ]}

// update metric values
updval:{[name;func;val].[`.prom.metricvals;(name;`val);func;val];}

// logic run inside event handlers
// null logic, to be overwritten
on_poll  :{[msg]}
on_po    :{[hdl]}
on_pc    :{[hdl]}
on_wo    :{[hdl]}
on_wc    :{[hdl]}
before_pg:{[msg]}
after_pg :{[tmp;msg;res]}
before_ps:{[msg]}
after_ps :{[tmp;msg;res]}
before_ph:{[msg]}
after_ph :{[tmp;msg;res]}
before_pp:{[msg]}
after_pp :{[tmp;msg;res]}
before_ws:{[msg]}
after_ws :{[tmp;msg;res]}
before_ts:{[dtm]}
after_ts :{[tmp;dtm;res]}

// event handlers
po:{[f;hdl]on_po hdl;f hdl}
pc:{[f;hdl]on_pc hdl;f hdl}
wo:{[f;hdl]on_wo hdl;f hdl}
wc:{[f;hdl]on_wc hdl;f hdl}
pg:{[f;msg]tmp:before_pg msg;res:f msg;after_pg[tmp;msg;res];res}
ps:{[f;msg]tmp:before_ps msg;res:f msg;after_ps[tmp;msg;res];}
ph:{[f;msg]$["metrics"~msg 0;
  [on_poll[msg];.h.hy[`txt]extractall[]];
  [tmp:before_ph msg;res:f msg;after_ph[tmp;msg;res];res]
 ]}
pp:{[f;msg]tmp:before_pp msg;res:f msg;after_pp[tmp;msg;res];res}
ws:{[f;msg]tmp:before_ws msg;res:f msg;after_ws[tmp;msg;res];}
ts:{[f;dtm]tmp:before_ts dtm;res:f dtm;after_ts[tmp;dtm;res];}

// overload existing event handlers
overloadhandler:{[nm;ol;def]
  fn:ol $[`err~rs:@[value;nm;`err];
    def;
    get(`$string[nm],"_orig")set rs
  ];
  nm set fn;}

// initialize library
init:{[]
  overloadhandler[`.z.po;po;{[x]}];
  overloadhandler[`.z.pc;pc;{[x]}];
  overloadhandler[`.z.wo;wo;{[x]}];
  overloadhandler[`.z.wc;wc;{[x]}];
  overloadhandler[`.z.pg;pg;value];
  overloadhandler[`.z.ps;ps;value];
  overloadhandler[`.z.ph;ph;{[x]}];
  overloadhandler[`.z.pp;pp;{[x]}];
  overloadhandler[`.z.ws;ws;{[x]}];
  overloadhandler[`.z.ts;ts;{[x]}];
 }
 
// from root context
\d .
 
// static info
infokeys:`release_date`release_version`os_version`process_cores`license_expiry_date
infovals:string[(.z.k;.z.K;.z.o;.z.c)],enlist .z.l 1

// metric classes
.prom.newmetric[`kdb_info;`gauge;infokeys;"process information"]
.prom.newmetric[`memory_usage_bytes;`gauge;();"memory allocated"]
.prom.newmetric[`memory_heap_bytes;`gauge;();"memory available in the heap"]
.prom.newmetric[`memory_heap_peak_bytes;`counter;();"maximum heap size so far"]
.prom.newmetric[`memory_heap_limit_bytes;`gauge;();"limit on thread heap size"]
.prom.newmetric[`memory_mapped_bytes;`gauge;();"mapped memory"]
.prom.newmetric[`memory_physical_bytes;`gauge;();"physical memory available"]
.prom.newmetric[`kdb_syms_total;`counter;();"number of symbols"]
.prom.newmetric[`kdb_syms_memory_bytes;`counter;();"memory use of symbols"]
.prom.newmetric[`kdb_ipc_opened_total;`counter;();"number of ipc sockets opened"]
.prom.newmetric[`kdb_ipc_closed_total;`counter;();"number of ipc sockets closed"]
.prom.newmetric[`kdb_ws_opened_total;`counter;();"number of websockets opened"]
.prom.newmetric[`kdb_ws_closed_total;`counter;();"number of websockets closed"]
.prom.newmetric[`kdb_handles_total;`gauge;();"number of open handles (ipc and websocket)"]
.prom.newmetric[`kdb_sync_total;`counter;();"number of sync requests"]
.prom.newmetric[`kdb_async_total;`counter;();"number of async requests"]
.prom.newmetric[`kdb_http_get_total;`counter;();"number of http get requests"]
.prom.newmetric[`kdb_http_post_total;`counter;();"number of http post requests"]
.prom.newmetric[`kdb_ws_total;`counter;();"number of websocket messages"]
.prom.newmetric[`kdb_ts_total;`counter;();"number of timer calls"]
.prom.newmetric[`kdb_sync_err_total;`counter;();"number of errors from sync requests"]
.prom.newmetric[`kdb_async_err_total;`counter;();"number of errors from async requests"]
.prom.newmetric[`kdb_http_get_err_total;`counter;();"number of errors from http get requests"]
.prom.newmetric[`kdb_http_post_err_total;`counter;();"number of errors from http post requests"]
.prom.newmetric[`kdb_ws_err_total;`counter;();"number of errors from websocket messages"]
.prom.newmetric[`kdb_ts_err_total;`counter;();"number of errors from timer calls"]
.prom.newmetric[`kdb_sync_summary_seconds;`summary;();"duration of sync requests"]
.prom.newmetric[`kdb_async_summary_seconds;`summary;();"duration of async requests"]
.prom.newmetric[`kdb_http_get_summary_seconds;`summary;();"duration of http get requests"]
.prom.newmetric[`kdb_http_post_summary_seconds;`summary;();"duration of http post requests"]
.prom.newmetric[`kdb_ws_summary_seconds;`summary;();"duration of websocket messages"]
.prom.newmetric[`kdb_ts_summary_seconds;`summary;();"duration of timer calls"]
.prom.newmetric[`kdb_sync_histogram_seconds;`histogram;();"duration of sync requests"]
.prom.newmetric[`kdb_async_histogram_seconds;`histogram;();"duration of async requests"]
.prom.newmetric[`kdb_http_get_histogram_seconds;`histogram;();"duration of http get requests"]
.prom.newmetric[`kdb_http_post_histogram_seconds;`histogram;();"duration of http post requests"]
.prom.newmetric[`kdb_ws_histogram_seconds;`histogram;();"duration of websocket messages"]
.prom.newmetric[`kdb_ts_histogram_seconds;`histogram;();"duration of timer calls"]

// metric instances
info      :.prom.addmetric[`kdb_info;infovals;();1f]
mem       :.prom.addmetric[`memory_usage_bytes;();();0f]
mem_heap  :.prom.addmetric[`memory_heap_bytes;();();0f]
mem_lim   :.prom.addmetric[`memory_heap_peak_bytes;();();0f]
mem_max   :.prom.addmetric[`memory_heap_limit_bytes;();();0f]
mem_map   :.prom.addmetric[`memory_mapped_bytes;();();0f]
mem_phys  :.prom.addmetric[`memory_physical_bytes;();();0f]
sym_num   :.prom.addmetric[`kdb_syms_total;();();0f]
sym_mem   :.prom.addmetric[`kdb_syms_memory_bytes;();();0f]
ipc_opened:.prom.addmetric[`kdb_ipc_opened_total;();();0f]
ipc_closed:.prom.addmetric[`kdb_ipc_closed_total;();();0f]
ws_opened :.prom.addmetric[`kdb_ws_opened_total;();();0f]
ws_closed :.prom.addmetric[`kdb_ws_closed_total;();();0f]
hdl_open  :.prom.addmetric[`kdb_handles_total;();();0f]
qry_sync  :.prom.addmetric[`kdb_sync_total;();();0f]
qry_async :.prom.addmetric[`kdb_async_total;();();0f]
qry_http  :.prom.addmetric[`kdb_http_get_total;();();0f]
qry_post  :.prom.addmetric[`kdb_http_post_total;();();0f]
qry_ws    :.prom.addmetric[`kdb_ws_total;();();0f]
qry_ts    :.prom.addmetric[`kdb_ts_total;();();0f]
err_sync  :.prom.addmetric[`kdb_sync_err_total;();();0f]
err_async :.prom.addmetric[`kdb_async_err_total;();();0f]
err_http  :.prom.addmetric[`kdb_http_get_err_total;();();0f]
err_post  :.prom.addmetric[`kdb_http_post_err_total;();();0f]
err_ws    :.prom.addmetric[`kdb_ws_err_total;();();0f]
err_ts    :.prom.addmetric[`kdb_ts_err_total;();();0f]
summ_sync :.prom.addmetric[`kdb_sync_summary_seconds;();.25 .5 .75;0#0f]
summ_async:.prom.addmetric[`kdb_async_summary_seconds;();.25 .5 .75;0#0f]
summ_http :.prom.addmetric[`kdb_http_get_summary_seconds;();.25 .5 .75;0#0f]
summ_post :.prom.addmetric[`kdb_http_post_summary_seconds;();.25 .5 .75;0#0f]
summ_ws   :.prom.addmetric[`kdb_ws_summary_seconds;();.25 .5 .75;0#0f]
summ_ts   :.prom.addmetric[`kdb_ts_summary_seconds;();.25 .5 .75;0#0f]
hist_sync :.prom.addmetric[`kdb_sync_histogram_seconds;();.25 .5 1 5 10;0#0f]
hist_async:.prom.addmetric[`kdb_async_histogram_seconds;();.25 .5 1 5 10;0#0f]
hist_http :.prom.addmetric[`kdb_http_get_histogram_seconds;();.25 .5 1 5 10;0#0f]
hist_post :.prom.addmetric[`kdb_http_post_histogram_seconds;();.25 .5 1 5 10;0#0f]
hist_ws   :.prom.addmetric[`kdb_ws_histogram_seconds;();.25 .5 1 5 10;0#0f]
hist_ts   :.prom.addmetric[`kdb_ts_histogram_seconds;();.25 .5 1 5 10;0#0f]

// memory metrics (.Q.w[])
memmetrics:value each`mem`mem_heap`mem_lim`mem_max`mem_map`mem_phys`sym_num`sym_mem

// define logic to run in event handlers
.prom.on_poll:{[msg].prom.updval[;:;]'[memmetrics;value"f"$.Q.w[]];}

.prom.on_po:{[msg]
  .prom.updval[ipc_opened;+;1];
  .prom.updval[hdl_open;:;"f"$count .z.W];}
.prom.on_pc:{[msg]
  .prom.updval[ipc_closed;+;1];
  .prom.updval[hdl_open;:;"f"$count .z.W];}
.prom.on_wo:{[msg]
  .prom.updval[ws_opened;+;1];
  .prom.updval[hdl_open;:;"f"$count .z.W];}
.prom.on_wc:{[msg]
  .prom.updval[ws_closed;+;1];
  .prom.updval[hdl_open;:;"f"$count .z.W];}
before:{[met;msg]
  .prom.updval[value`$"qry_",met;+;1];
  .prom.updval[value`$"err_",met;+;1];
  .z.p}
after:{[met;tmp;msg;res]
  .prom.updval[value`$"err_",met;-;1];
  tm:(10e-9)*.z.p-tmp;
  .prom.updval[value`$"summ_",met;,;tm];
  .prom.updval[value`$"hist_",met;,;tm];}
.prom.before_pg:before"sync"
.prom.after_pg :after"sync"
.prom.before_ps:before"async"
.prom.after_ps :after"async"
.prom.before_ph:before"http"
.prom.after_ph :after"http"
.prom.before_ph:before"post"
.prom.after_ph :after"post"
.prom.before_ws:before"ws"
.prom.after_ws :after"ws"
.prom.before_ts:before"ts"
.prom.after_ts :after"ts"

// initialize library
.prom.init[]