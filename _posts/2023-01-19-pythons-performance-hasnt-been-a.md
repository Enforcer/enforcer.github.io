--- 
layout: post
title: Python's performance hasn't been a top priority. It's changing now
description:
date: 2023-01-19 20:37:06 +0100
published: true 
categories: []
tags: []
lang: 
---

When I was a teenager who knew PHP basics, I wondered which programming language to learn next. After some hesitation, I chose Java. I bought a book and started writing simple programs with GUI.

A few months later when I was 16 or 17, our IT teacher organized additional classes with a university teacher so we could get to know algorithms and data structures. The ultimate goal was to prepare volunteers for the IT contest. We worked with C++. Then I, a Java greenhorn, asked why we don’t use that language instead. In the answer, I got the following joke:

- knock, knock?

- who’s there?

- … \<few awkward seconds of silence\>

- Java!

Then the university teacher explained that Java is slow. So I dumped it and bought C++ books instead. For language’s speed which I thought was crucial.

Fast-forward 15 years and I’m a Python software engineer. It’s definitely the slowest mainstream programming language around there. Ironic, isn’t it?

## Languages do evolve

While most languages I used in the past made tremendous progress regarding performance - that includes both Java and PHP.

For Python optimizations were not a priority. To be fair, it also went through enormous changes through the last 10 years I use it - asyncio was added or type annotations just to name a few. Those were huge steps that made Python and its ecosystem to thrive, yet those were not about speed (I’d say asyncio is not about speed - but another concurrency model, which is NOT the same thing and was around even before it - still remember [Twisted](https://twisted.org/), [Tornado](https://www.tornadoweb.org/en/stable/) or magical [gevent](https://www.gevent.org/)?).

## Speeding up Python

However, [since the last few minor Python versions, we see more and more performance improvements coming in](https://speed.python.org/comparison/) with a huge improvement in 3.11. And more improvements are coming in. Yay!

I don’t even want to start about GIL removal (mentioned in the previous substack post) or [Pypy](https://www.pypy.org/). It’s enough to say a lot is moving in the topic.

Here’s an interview with Guido van Rossum about the future of the language: [https://thenewstack.io/guido-van-rossum-on-types-speed-and-the-future-of-python/](https://thenewstack.io/guido-van-rossum-on-types-speed-and-the-future-of-python/)

## Who will benefit from that?

Everyone, to be honest. While the developer’s productivity is more important than pure execution speed, it’s still very nice to have fewer servers or wait for less for test results.

One truism though - it doesn’t mean one shouldn’t care about performance when their Python program is slow. Before we make any optimizations though it’s vital to measure the program and find the bottleneck. You’ll find links to profiling tools below.

## What’s the most often thing I optimize?

Test suite speed. I use two metrics:

- how much time does it take from starting up the test suite to its completion?

- how long it takes to start and finish one single tiny unit test (bootstrap time)?

To measure those you need just [snakeviz](https://jiffyclub.github.io/snakeviz/) package and built-in [cProfile](https://docs.python.org/3/library/profile.html):

    python -m cProfile -o results.prof $(which pytest) <path to a tests (first metric) or a single test (second metric)>
    snakeviz results.prof

After executing a second command a browser window would be opened with graphical depiction of profiling.

## Tracing profilers

- [cProfile](https://docs.python.org/3/library/profile.html) (built-in!)

- [Yappi](https://pypi.org/project/yappi/)

## Sampling profilers

- [py-spy](https://github.com/benfred/py-spy)

- [pyinstrument](https://github.com/joerick/pyinstrument)

## Memory profilers

- [memray](https://bloomberg.github.io/memray/)

## Profiling CPU & Memory

- [scalene](https://github.com/plasma-umass/scalene)

## Other links

- [hammet](https://github.com/boxed/hammett) - alternative test runner with opt, partially backwards compatible with pytest

- [nox](https://nox.thea.codes/en/stable/) - a tool to test in multiple python environments e.g. with different Python versions

