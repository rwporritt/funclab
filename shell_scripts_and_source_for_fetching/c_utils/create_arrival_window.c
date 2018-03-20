#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Code reads a time string like:
 2007/02/17 00:02:57.4300
 converts it to epoch time and adds an hour, then spits back in same format
 
 unlike add_an_hour.c, this code takes a duration (in seconds) and a center time point (arrival prediction) and spits out time strings for the start and end
 
 variables tright, tleft, timeRight, and timeLeft are if you imagine time as the x axis increasing to the right
 
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
    int hour, minute;
    double second, offsetTime, leadWindow, endWindow;
    struct tm tstart, tleft, tright;
    time_t timeStart, timeLeft, timeRight, timeCenter;
    char buff1[80], buff2[80];

    
    //checks usage
    if (argc != 6) {
        fprintf(stdout,"Usage: %s year/month/day hour:min:sec.decsec WindowCenter(secondsFromTimeString) leadWindow(seconds) endWindow(seconds)\n",argv[0]);
        fprintf(stdout,"The idea here is that the time string is the earth quake origin and the window center is your desired arrival's predicted travel time.\nThe code then returns time strings from leadWindow to endWindow centered about the windowcenter\n");
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
    sscanf(argv[1],"%d/%d/%d",&year,&month,&day);
    sscanf(argv[2],"%d:%d:%lf",&hour,&minute,&second);
    sscanf(argv[3],"%lf",&offsetTime);
    sscanf(argv[4],"%lf",&leadWindow);
    sscanf(argv[5],"%lf",&endWindow);

    // convert input time to sturcture
    tstart.tm_year = year-1900;
    tstart.tm_mon = month-1;
    tstart.tm_mday = day;
    tstart.tm_hour = hour;
    tstart.tm_min = minute;
    tstart.tm_sec = second;
    tstart.tm_isdst = -1;
    
    //convert epoch time and find offsets
    timeStart = mktime(&tstart);
    timeCenter = timeStart + offsetTime;
    timeRight = timeCenter + endWindow;
    timeLeft = timeCenter - leadWindow;
    
    //return to utc time
    tleft = *localtime(&timeLeft);
    tright = *localtime(&timeRight);
    
    //prepare as strings and print. Format is for FetchData input (YYYY-MM-DD,HH:MM:SS.ssssss)
    //strftime(buff1,sizeof(buff1), "%Y/%m/%d %H:%M:%S", &tleft);
    //strftime(buff2,sizeof(buff2), "%Y/%m/%d %H:%M:%S", &tright);
    strftime(buff1,sizeof(buff1),"%Y-%m-%d,%H:%M:%S",&tleft);
    strftime(buff2,sizeof(buff2),"%Y-%m-%d,%H:%M:%S",&tright);
    fprintf(stdout,"%s %s\n",buff1, buff2);
    
    
    return 0;
}
