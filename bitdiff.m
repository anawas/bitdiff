/*!
    @header bitdiff.m
    @abstract   Compares to files bitwise.
    @discussion The standard UNIX tool to compare two files is 'diff' (see
	manual pages 'man diff' for further information). This tool reports the 
	differences between two files. It can handle any type of files and does a
	really good job.

	This tool here does a similar job, but prints out in addition which bits
	differ from each other in two characters. 
*/

#import <Foundation/Foundation.h>

#define VERSION		"This is bitdiff Version 0.9"
#define BUILD		"libtiff:build:20082006:1830"
#define USAGE		"file1 file2"

uint32_t bitArray[8];
uint32_t counter;

/*!
    @function
    @abstract   Clears the bit counting array
    @discussion The application uses a array to store the frequency of each different bit.
				This aray is initialized (i.e. set to zero) here. 
    @param      none
    @result     none
*/
void initBitArray() {
	int i;
	for (i = 0; i < 8; i++) {
		bitArray[i] = 0;
	}
}

/*!
    @function
    @abstract   Prints out the bit array
    @discussion The contents of the bit array are print out to the screen. There is
				also a small statistics.
    @param      none
    @result     none
*/
void printBitArray() {
	int i;
	int nErrors = 0;
	
	fprintf(stdout, "\n\nStatistics on found bit errors:\n");
	fprintf(stdout, "===============================\n");
	for (i = 0; i < 8; i++) {
		fprintf(stdout, " %4d |", i+1);
	}
	
	fprintf(stdout, "\n");

	for (i = 0; i < 8; i++) {
		fprintf(stdout, " %ld |", bitArray[i]);
		nErrors += bitArray[i];
	}	

	fprintf(stdout, "\n");

	for (i = 0; i < 8; i++) {
		fprintf(stdout, " %0.2f%% |", (bitArray[i] / (float)nErrors)*100.0);
	}	
}

/*!
    @function
    @abstract   Compares two bytes bitwise.
    @discussion This function compares to given values (bytes) bitwise. If it detects any
				differences then they are prrint out. 
    @param      value1 The first byte (the original/the source byte)
				vylue2 The second byte (the target byte)
    @result     True if the two bytes are equal
				False otherwise.
*/
BOOL bitsEqual (uint8_t value1, uint8_t value2) {
	int cnt;
	BOOL isEqual;
	
	isEqual = YES;
	cnt = 0;
	
	while (++cnt <= 8) { 
		if ((value1 & 0x1) != (value2 & 0x1)) {
			if (isEqual) {
				printf("\n\nBit error in byte %ld\n", counter);
				printf("Different bits at position: ");
				isEqual = NO;
			}

			++bitArray[cnt-1];
			printf("%d ", cnt);
		}
		value1 >>= 1;
		value2 >>= 1;
	}
	
	return isEqual;
}

/*!
    @function
    @abstract   Converts a byte to its binary representation.
    @discussion The function takes a byte as input and converts it to its binary
				representation, which is a NSString. Used to print out the result 
				of the comparison.
    @param      value The byte to be converted
    @result     NSString holding the binary representation of the byte.
*/
NSString *convertToBinary (uint8_t value) {
	
	NSMutableString *binVal = [NSMutableString stringWithCapacity:8];
	
	char* str; char* p;
	
	str = malloc(sizeof(uint8_t) * 8 * sizeof(char));
	p = str;
	
	int counter = 0;
	
	while(++counter <= 8)
	{
		/* bitwise AND operation with the last bit */
		(value & 0x1) ? (*p++='1') : (*p++='0'); 
		/* bit shift to the right, when there are no
		 bits left the value is 0, so the loop ends */
		value >>= 1; 
	}

	while( p-- != str ) {/* print out the result backwards */
		NSString *nsStr = [[NSString stringWithFormat:@"%c", *p] autorelease];
		[binVal appendString: nsStr];
	}
	free(str);	;
	return binVal;
}

/*********************************************************************/
/*** main program												   ***/
/*********************************************************************/
 int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	fprintf(stdout, "%s\n%s\n", VERSION, BUILD);
	
	if (argc <= 1) {
		fprintf(stdout, "Usage: %s %s\n", argv[0], USAGE);
		exit (1);
	}
	
	 uint16_t nBitErrors = 0;
	 
	NSString *inf1 = [NSString stringWithUTF8String: argv[1]];
	NSString *inf2 = [NSString stringWithUTF8String: argv[2]];

	NSInputStream *origFile = NULL;
	NSInputStream *rescanFile = NULL;
	
	NSLog(@"open %@ ...", inf1);
	origFile = [NSInputStream inputStreamWithFileAtPath: inf1];
	if (origFile == nil) {
		NSLog(@"Error opening file %s", [inf1 UTF8String]);
		goto cleanup;
	}

	NSLog(@"comparing to %@ ...", inf2);
	rescanFile = [NSInputStream inputStreamWithFileAtPath: inf2];
	if (rescanFile == nil) {
		NSLog(@"Error opening file %s", [inf2 UTF8String]);
		goto cleanup;
	}
	
	// A buffer to hold one character
	uint8_t *charBuf1 = malloc(1 * sizeof(char));
	uint8_t *charBuf2 = malloc(1 * sizeof(char));
	
	[origFile open];
	[rescanFile open];
	
	initBitArray();
	counter = 0;

	while (([origFile hasBytesAvailable]) && 
				 ([rescanFile hasBytesAvailable])) {
		[origFile read:charBuf1 maxLength: 1];
		[rescanFile read:charBuf2 maxLength: 1];
		
		if (bitsEqual(charBuf1[0], charBuf2[0]) == NO) {
			++nBitErrors;
			printf("\nExpected: %s (%c)  ", [[NSString  stringWithString: convertToBinary(charBuf1[0])] UTF8String], charBuf1[0]);
			printf("but found: %s (%c)", [[NSString  stringWithString: convertToBinary(charBuf2[0])] UTF8String], charBuf2[0]);
		}
		++counter;
	}

	[origFile close];
	[rescanFile close];
	
	fprintf(stdout, "\n\nBytes compared: %ld\n", counter);
	
	if (nBitErrors != 0) {
		fprintf(stdout, "%d bytes with bit error(s) detected (%2.2f%%)\n\n", nBitErrors, ((float)nBitErrors/counter)*100.0);
		printBitArray();
	} else {
		fprintf(stdout, "NO bit errors detected. Files seem to be identical.\n\n");
	}
	
cleanup:
	if (charBuf2 != NULL) {
		free(charBuf2);
	}

	if (charBuf1 != NULL) {
		free(charBuf1);
	}

	[pool drain];
	return 0;
}
