\d .
.time.toMillis:{:`long$x%1e6 - 1970.01.01+00:00:00}
.time.toTimespan:{:(1970.01.01+00:00:00)+`timespan$1e6*x}

.time.startOfYear:{"d"$ceiling 365.245*-2000+x}
.time.startOfMonth:{"d"$x+0D00:00}

.sym.notEmpty:{r: 0b;$[(101h = type x) or (count[x] = 1);$[0b = null x;r: 1b]];$[(count[x] > 1);r: 1b];r}
.vars.isExist:{x~key x}

/ convert timestamp to unix-timestamp
/ ex) {floor((`long$x)-`long$1970.01.01D00:00)%1e9} 2020.11.18D13:34:51.000000000 -> 1605706491
.timestamp.toUnixTimestamp:{floor((`long$x)-`long$1970.01.01D00:00)%1e9}
/ convert unix-timestamp to timestamp 
/ ex) {"P"$ string x} 1605706491 -> 2020.11.18D13:34:51.000000000
.unixTimestamp.toTimestamp:{"P"$ string x} 1605706491
/ convert date to timestamp
/ ex) {x+0D00:00:00.000000000} 2020.11.18 -> 2020.11.18D00:00:00.000000000
.date.toTimestamp:{x+0D00:00:00.000000000}