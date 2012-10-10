#ifndef QPERFORMANCE_TIMER_H
#define QPERFORMANCE_TIMER_H
	
/********************************************************************************
	Copyright (C) 2004 Sjaak Priester	

	This is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This file is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Tinter; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
********************************************************************************/

/**********************************************
 * Largely modified by Taesoo Kwon.
/*
 * usage
 *
 * QPerformanceTimerCount2 gTimer2;
 *
 *
 * for (int i=0; i<100; i++)
 * {
 * gTimer.start();
 *
 * //do some thing
 *
 * gTimer.pause();
 * }
 *
 * // print sum of time between start and pause 
 * printf("%g\n",(double)gTimer.stop()/1000.0);
 *
 *
*/

#ifdef _MSC_VER
#else
#include <sys/time.h> 
#include <unistd.h> 
#endif

class QPerformanceTimerCount2
{
public:
	QPerformanceTimerCount2()
	{
#ifdef _MSC_VER
		reset();
		minTime=INT_MAX;
		maxTime=0;
#else
		reset();
#endif
	}

	~QPerformanceTimerCount2(void){}

	void reset()
	{
#ifdef _MSC_VER
		m_Sum.QuadPart=0;
#else
		m_Sum=0;
#endif
		m_count=0;
		state=0;
	}

	void start()
	{
#ifdef _MSC_VER
		::QueryPerformanceCounter(&m_Start);
#else

#ifdef USE_GETTIMEOFDAY
		gettimeofday(&m_Start, NULL);
#else
		//m_Start=clock();
		clock_gettime(CLOCK_MONOTONIC_COARSE, &m_Start);
#endif
		
#endif
		state=1;
	}

	inline void pause()
	{
		if(state!=1) 
			return;
#ifdef _MSC_VER
		::QueryPerformanceCounter(&m_Stop);

		m_Sum.QuadPart+=m_Stop.QuadPart-m_Start.QuadPart;
#else

#ifdef USE_GETTIMEOFDAY
		gettimeofday(&m_Stop, NULL);
		unsigned long microseconds=
			(m_Stop.tv_sec-m_Start.tv_sec)*1000000+(m_Stop.tv_usec-m_Start.tv_usec);
#else
		//m_Stop=clock();
		//unsigned long microseconds= (m_Stop-m_Start)*1000000/CLOCKS_PER_SEC;
		clock_gettime(CLOCK_MONOTONIC_COARSE, &m_Stop);
		unsigned long microseconds=
			(m_Stop.tv_sec-m_Start.tv_sec)*1000000+(m_Stop.tv_nsec-m_Start.tv_nsec)/1000;
#endif
		m_Sum+=microseconds;
#endif
		m_count++;
		state=2;
	}

	inline long stop()
	{
		if(state==1) pause();
		int micro=end();
#ifdef _MSC_VER
		minTime=MIN(micro, minTime);
		maxTime=MAX(micro, maxTime);
#endif
		reset();
		return micro;
	}

protected:
	int state;
	inline long end()
	{
#ifdef _MSC_VER
		LARGE_INTEGER freq;

		::QueryPerformanceFrequency(&freq);

		m_Sum.QuadPart *= 100000;
		m_Sum.QuadPart /= freq.QuadPart;

		if (m_Sum.HighPart != 0) return -1;
		return m_Sum.LowPart;
#else
		return m_Sum;
#endif
	}
#ifdef _MSC_VER
	LARGE_INTEGER m_Start;
	LARGE_INTEGER m_Stop;
	LARGE_INTEGER m_Sum;
#else
#ifdef USE_GETTIMEOFDAY // HIGH RESOLUTION but SLOWWWWWW
	struct timeval m_Start;
	struct timeval m_Stop;
#else  // LOW RESOLUTION
	//clock_t m_Start;
	//clock_t m_Stop;
	timespec m_Start, m_Stop;
#endif
	long m_Sum;
#endif
	int m_count, m_gran, minTime, maxTime;
};

class FractionTimer 
{
	static QPerformanceTimerCount2 gTimerInside;
	static QPerformanceTimerCount2 gTimerOutside;
	static int gCount;
	static double gOverhead;
public:
	inline FractionTimer()
	{
		gTimerInside.start();
		gTimerOutside.pause();
		gCount++;
	}

	static void init()
	{
		{
			// measure profiling overhead
			gTimerInside.reset();
			gTimerOutside.reset();
			gTimerOutside.start();
			int N=100000;
			for (int i=0; i<N; i++)
			{
				gTimerInside.start();
				gTimerInside.pause();
			}
			gOverhead=gTimerOutside.stop()/1000.0/(double)N;
			//printf("gOverhead %g %g\n", gOverhead*N, gTimerInside.stop()/1000.0);
		}
		gTimerInside.reset();
		gTimerOutside.reset();
		gTimerOutside.start();
		gCount=0;
	}
	static double stopInside()
	{
		return (double)gTimerInside.stop()/1000.0;
	}
	static double stopOutside()
	{
		return (double)gTimerOutside.stop()/1000.0;
	}

	static void printSummary(const char* msg, const char* insideName, const char* outsideName)
	{
		double inside=stopInside();
		double outside=stopOutside();
		double overhead=gOverhead*gCount;
#ifdef USE_GETTIMEOFDAY 
		double errorCorrection=0.4;
#else
		double errorCorrection=0;
#endif
		printf("Profiling %s finished: %s %gms, %s %gms, profiling overhead %gms, total time %gms\n", msg, insideName, inside-overhead-overhead*errorCorrection, outsideName, outside-overhead-overhead*errorCorrection, overhead*2, inside+outside-overhead*errorCorrection*2);
		// init without measuring
		gTimerInside.reset();
		gTimerOutside.reset();
		gCount=0;
		gTimerOutside.start();
	}

	static int count()
	{
		return gCount;
	}
	inline ~FractionTimer(void)
	{
		gTimerOutside.start();
		gTimerInside.pause();
	}
};
#endif
