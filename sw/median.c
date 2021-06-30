#include <stdio.h>
#include <stdlib.h>
#include "tv.h"

#define ITR 256

int main(void) {
	FILE *fp;
	int i, j, k, l, temp;
	unsigned char arr[8];

	fp = fopen("./sw_result.txt", "w");

	if (fp == NULL)
	{
		printf("error occurs when opening sw_result.txt!\n");
		exit(1);
	}
	i = 0;
	while (i < ITR) {
		l = 0;
		while (l < 8) {
			arr[l] = a[i];
			i = i + 1;
			l = l + 1;
		}

		j = 0;
		while (j < 8) {
			k = j + 1;
			while (k < 8) {
				if (arr[j] > arr[k]) {
					temp = arr[k];
					arr[k] = arr[j];
					arr[j] = temp;
				}
				k = k + 1;
			}
			j = j + 1;
		}
		fprintf(fp, "%02x\n", (arr[3] + arr[4]) / 2);
	}

	fclose(fp);

	return 0;
}