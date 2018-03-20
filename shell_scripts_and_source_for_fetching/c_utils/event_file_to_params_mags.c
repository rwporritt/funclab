#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/*
 Command to parse FetchEvent file into desired params
 */

int main (int argc, char *argv[]){

    int id, year, month, day, hour, min;
    double sec, lat, lon, depth, mag;
    char buff[200], infileName[200], magsFileName[200];
    char junk1[100];
    FILE *infile, *magsFile;

    if (argc != 3 ) {
        fprintf(stderr,"Usage: %s fileFromFetchEvent magnitudeFile\n",argv[0]);
        fprintf(stderr,"Note, it must be in the default | separated format\n");
        fprintf(stderr,"You can make the magnitudeFile with an awk like:\n");
        fprintf(stderr,"   awk -F\"|\" '{print $9}' $eventOutFile  | awk -F\",\" '{print $2}' > tmp.mag\n");
        exit(1);
    }

    sscanf(argv[1],"%s",infileName);
    if ((infile = fopen(infileName,"r")) == NULL) {
        fprintf(stderr,"Error, file %s not found\n",infileName);
        exit(1);
    }
    sscanf(argv[2],"%s",magsFileName);
    if ((magsFile = fopen(magsFileName,"r")) == NULL) {
        fprintf(stderr,"Error, file %s not found\n",magsFileName);
        exit(1);
    }

    while (fgets(buff,200,infile)) {
        sscanf(buff,"%d | %d/%d/%d %d:%d:%lf | %lf | %lf | %lf | %[A-Z,a-z,|, ,-], %lf",&id, &year, &month, &day, &hour, &min, &sec, &lat, &lon, &depth, junk1, &mag);
        //printf("%s %lf\n",junk1, mag);
        fscanf(magsFile,"%lf",&mag);
        fprintf(stdout,"%02d/%02d/%02d_%02d:%02d:%02.4lf_%3.3lf_%3.3lf_%3.3lf_%3.3lf\n",year,month,day,hour,min,sec,lat,lon,depth,mag);

    }


    fclose(infile);
    fclose(magsFile);


    return 0;
}
