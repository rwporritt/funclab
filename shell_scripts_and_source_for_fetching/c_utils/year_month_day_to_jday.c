#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Code reads a time string like:
year month day
 and returns just
 jday
 */


/* examples
 int main(void)
 {
 time_t     now;
 struct tm  ts;
 char       buf[80];
 // Get current time
 time(&now);
 // Format time, "ddd yyyy-mm-dd hh:mm:ss zzz"
 ts = *localtime(&now);
 strftime(buf, sizeof(buf), "%a %Y-%m-%d %H:%M:%S %Z", &ts);
 printf("%s\n", buf);
 return 0;
 }
 
 struct tm t;
 time_t t_of_day;
 t.tm_year = 2011-1900;
 t.tm_mon = 7;           // Month, 0 - jan
 t.tm_mday = 8;          // Day of the month
 t.tm_hour = 16;
 t.tm_min = 11;
 t.tm_sec = 42;
 t.tm_isdst = -1;        // Is DST on? 1 = yes, 0 = no, -1 = unknown
 t_of_day = mktime(&t);
 printf("seconds since the Epoch: %ld\n", (long) t_of_day)
 */

int main (int argc, char *argv[]) {
    
    int year, month, day;
    struct tm tstart, tOut;
    time_t timeStart;
    
    //checks usage
    if (argc != 4) {
        fprintf(stdout,"Usage: %s year month day\n",argv[0]);
        fprintf(stdout,"Converts from year month day to julian day\n");
        exit(1);
    }
    
    // scans - format is based on iris's FetchEvent script
    // use a command like:
    //FetchData -s 2007-01-01,00:00:00.000 --radius 38.7:-9.1833:120:30 --mag 6.0:9.0  -o tmp.evt
    //awk -F"|" '{print $2}' tmp.evt > tmp.evt.in
    //foreach evt ( `awk '{print $1"_"$2}' tmp.evt.in`)
    //  set firstpart = `echo $evt | awk -F"_" '{print $1}'`
    //  set secondpart = `echo $evt | awk -F"_" '{print $2}'`
    //  plushour = `add_an_hour $firstpart $secondpart`
    sscanf(argv[1],"%d",&year);
    sscanf(argv[2],"%d",&month);
    sscanf(argv[3],"%d",&day);
    
    // convert input time to sturcture
    tstart.tm_year = year-1900;
    tstart.tm_mon = month-1;
    tstart.tm_mday = day;
    tstart.tm_hour = 0;
    tstart.tm_min = 0;
    tstart.tm_sec = 0;
    tstart.tm_isdst = -1;
    
    //convert epoch time
    timeStart = mktime(&tstart);
    
    //return to utc time
    tOut = *localtime(&timeStart);
    
    //output just julian day
    fprintf(stdout,"%d\n",tOut.tm_yday+1);
    
    return 0;
}
