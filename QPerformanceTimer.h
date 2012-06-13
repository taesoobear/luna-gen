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
		gettimeofday(&m_Start, NULL);
#endif
		state=1;
	}

	void pause()
	{
		if(state!=1) 
			return;
#ifdef _MSC_VER
		::QueryPerformanceCounter(&m_Stop);

		m_Sum.QuadPart+=m_Stop.QuadPart-m_Start.QuadPart;
#else
		gettimeofday(&m_Stop, NULL);
		unsigned long microseconds=
			(m_Stop.tv_sec-m_Start.tv_sec)*1000000+(m_Stop.tv_usec-m_Start.tv_usec);
		m_Sum+=microseconds;
#endif
		m_count++;
		state=2;
	}

	long stop()
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
	long end()
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
	struct timeval m_Start;
	struct timeval m_Stop;
	long m_Sum;
#endif
	int m_count, m_gran, minTime, maxTime;
};

class FractionTimer 
{
	static QPerformanceTimerCount2 gTimerInside;
	static QPerformanceTimerCount2 gTimerOutside;
public:
	FractionTimer()
	{
		gTimerInside.start();
		gTimerOutside.pause();
	}

	static void init()
	{
		gTimerInside.reset();
		gTimerOutside.reset();
		gTimerOutside.start();
	}
	static double stopInside()
	{
		return (double)gTimerInside.stop()/1000.0;
	}
	static double stopOutside()
	{
		return (double)gTimerOutside.stop()/1000.0;
	}

	~FractionTimer(void)
	{
		gTimerInside.pause();
		gTimerOutside.start();
	}
};
#endif
