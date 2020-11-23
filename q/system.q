\d .system

summary: `operating_system`physical_cores`process_id`quiet_mode`version`init_script`host`timestamp!(.z.o;.z.c;.z.i;.z.q;.z.K;.z.f;.z.h;.z.p);
license: `maxCoresAllowed`expiryDate`updateDate`````bannerText`!.z.l;
version: `version`release_date!(.Q.k;.Q.K);
parameters: .Q.opt .z.x;

-1"Current OS: ", string .z.o;
-1"Q process running using ", (string .z.i), "!.";

\d .

sysout:{-1 raze["T"sv string`date`second$.z.P]," ",x," - ",y}
.log.error:{sysout["[ERROR]"]x}
.log.debug:{sysout["[DEBUG]"]x}
.log.info:{sysout["[INFO]"]x}
