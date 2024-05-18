--- 
layout: post
title: Which library is the best for writing BDDs in Python &amp; listening to your tests
description:
date: 2023-01-12 20:22:05 +0100
published: true 
categories:
- testing
tags: []
lang: 
permalink: "/which-library-is-the-best-for-writing-bdd-in-python/"
---

## pip install BDD?

There are two popular libraries that help writing BDD specifications in Python - [pytest-bdd](https://github.com/pytest-dev/pytest-bdd)and [behave](https://github.com/behave/behave).

Both are popular, actively maintained and feature-complete. I worked with both of them in the past and I spotted no serious issues (anecdotal evidence, your mileagage may wary).

Success with BDDs doesn’t depend on the tool, though. I recently read a book Specification by Example by Gojko Adzic. It emphasizes that tools are not what’s causing issues with specifications and also tools won’t fix them.

I strongly recommend [Gojko’s book](https://gojko.net/books/specification-by-example/). It has a lot of insights and is based on a solid research, not author’s gut feelings.

## Why do we even do BDD?

The goal of BDDs (or other form of executable specifications) IS NOT testing. It’s ensuring an ongoing collaboration between stakeholders, developers, testers and business analysts (or whoever participates in your dev process). Second goal is having an ever-green, executable documentation. Lastly, BDDs are giving great hints about architecture smells.

Which brings us to second topic today, listening to your tests (or specs as Gojko put it).

## Listening to your tests

Turns out there’s a huge overlap between BDD and DDD. Simply saying, if you find it hard to write down a scenario using Gherkin, it may mean your underlying architecture is too convoluted or you’re trying to specify too much at once. In DDD terms, you may have missed a subdomain.

Dan North shows it perfectly in an article:

- [Dan North - Whose Domain Is It Anyway?](https://dannorth.net/2011/01/31/whose-domain-is-it-anyway/)

For more interesting cases regarding BDDs see this case study, from three different angles:

- [Gojko Adzic - Handling Date Constraints In Your Scenarios](https://specflow.org/challenges/relative-periods/)

- [Seb Rose - Specifying relative time periods in feature files](https://cucumber.io/blog/bdd/specifying-relative-time-periods-in-feature-files/)

- [Dan North - The mystery of the missing date](https://dannorth.net/2020/11/26/the-mystery-of-the-missing-date/)

Of course, BDD is not a silver bullet and it won’t provide sufficient nor convenient full test coverage. Some tests are simply more technical and those don’t fit into specifications.

## Other links

### Wardley Maps

- [(talk) An introduction to Wardley Maps](https://www.youtube.com/watch?v=L3wgzl2iUR4)

### Gilectomy (again)

- [PEP 703 - Making the Global Interpreter Lock Optional in CPython](https://peps.python.org/pep-0703/)

- [Past efforts - Quora Thread](https://www.quora.com/What-happened-to-Larry-Hastings-and-the-Python-GILectomy-GIL-removal-project)

### IoC containers in Python

- [Lagom](https://lagom-di.readthedocs.io/en/latest/)

- [Injector](https://injector.readthedocs.io/en/latest/)

- [Dependency Injector](https://python-dependency-injector.ets-labs.org/)

