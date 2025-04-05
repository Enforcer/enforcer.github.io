--- 
layout: post
title: Is 100% code coverage a myth?
description:
date: 2023-03-02 19:54:24 +0100
published: true 
categories: []
tags: []
lang: 
---

## From manual tests to automated ones

I remember very vividly times when the only way for me to verify my code was to perform repetitive, mundane and error-prone manual testing. It was a huge progress to get into automated testing.

## Meet code coverage

Simply saying, code coverage says how much code has been tested. It can work on a line level - then 100% code coverage means that every line in the code has been executed at least once. It is pretty weak, so we should use more advanced types, such as branch coverage.

See my article ([how to use code coverage in Python](https://breadcrumbscollector.tech/how-to-use-code-coverage-in-python-with-pytest/)) for more basic information.

## How much coverage is needed?

When I first learned about code coverage, I was so fascinated by the idea that I strived very hard to get magical 100%. It was pretty easy to get 80-90%, but getting the rest code tested turned out to be very tricky.

I ended up writing some poor-quality tests, e.g. without assertions. Then I got disappointed by the whole idea and tried to be more pragmatic from now on.

From what I heard from other people, many had similar experiences - sometimes without stage when they tried to get to 100%. They perceive a 100% code coverage as Yeti - merely a legend or at least something highly unpractical.

Despite that, today I enforce 100% code coverage in projects I work with on a daily basis - this is required in the build system during CI.

## Don’t fix on the metric dude, fix your software development process instead

The difference between me 8-9 years ago and today is that I have a completely different way of working. **I am not struggling or focusing on getting 100% code coverage - the work is organized in such a way I am missing it only when I do something wrong**.

Instead of trying to test everything/starting from the unit-test level, I work from the top to the bottom.

BTW, unit testing originally WAS NOT about verifying a single function or class. Also, back in 1995 when jUnit was created, mocks weren’t a thing.

I start with high-level acceptance tests that focus on the user’s perspective, e.g.

```python
    def test_customer_can_read_stored_payment_card_details(
        authorized_client: TestClient,
    ) -> None:
        add_response = authorized_client.post(
            "/payment-cards",
            json={
                "card_number": "4111 1111 1111 1111",
                "names": "John Doe",
                "cvc": "123",
            },
        )
        assert add_response.status_code == 201
    
        get_response = authorized_client.get("/payment-cards")
        assert get_response.status_code == 200
        assert get_response.json() == [
            {
                "card_number": "4111 ******** 1111",
                "names": "John Doe",
                "cvc": "***",
            }
        ]
```

Such a test can be implemented on the API level; usually, I’d introduce some layers of abstractions or leverage Gherkin.

When we start from the top, such a test automatically gives us very high coverage (for simple features it will be 100% from the start). Then we can proceed with other scenarios, e.g.:

```python
    def test_initially_customer_has_no_saved_payment_cards() -> None:
        ...
    
    
    def test_customer_can_read_only_payment_cards_they_created() -> None:
        ...
```

A friend of mine, Łukasz, wrote a pretty long article how his development process with 100% code coverage looks like:

- [Why I find 100% code coverage very useful](https://lukeonpython.blog/2021/11/why-i-find-100-code-coverage-very-useful/)

## Prerequisites and auxiliary questions

It may happen that we’re unable to come up with a reasonable test scenario. It may be because the task we’re working on is not a [vertical slice](https://www.visual-paradigm.com/scrum/user-story-splitting-vertical-slice-vs-horizontal-slice/); in other words, it’s impossible to verify it from the user’s perspective (or external system that e.g. gets notified).

For example, a User Story: “_A customer can add their payment card_” is not verifiable.

If we get such a requirement, we can resort to one of auxiliary questions:

- where a user can see some change after their action?

- Which system functions for those users are affected?

- What a user can now do that they weren’t able to before?

- What a user can no longer do that they could before?

## Benefits

One needs to be aware that code coverage is NOT a metric of how extensively a system is tested. That one is really tricky to measure. After all, we can only test what we know. Here’s an article that elaborates on the topic: [Measurement of the Extent of Testing](https://sqa.fyicenter.com/art/Measurement_of_the_Extent_of_Testing.html).

However, 100% code coverage at least makes sure every line of code is exercised. That’s (from my experience) just enough to:

- eliminate many silly mistakes (they often crowd in those uncovered lines)

- be able to upgrade Python or dependencies versions with confidence enough to deploy to production and monitor there

- guide software development process.

It’s also worthwhile to get familiar with coverage-py author’s article about flaws in code coverage:

- [Flaws in coverage measurement](https://nedbatchelder.com/blog/200710/flaws_in_coverage_measurement.html)

## What’s next?

As I said before, even with 100% code coverage we cannot say are fully covered. Your QA strategy can be strengthened with other techniques:

### Code/automated test level:

- property-based testing with [hypothesis](https://hypothesis.readthedocs.io/en/latest/)

- mutation testing with e.g. [mutpy](https://github.com/mutpy/mutpy), [mutmut](https://mutmut.readthedocs.io/en/latest/) or [cosmic ray](https://cosmic-ray.readthedocs.io/en/latest/)

### Techniques:

- exploratory testing (can’t automate that)

### Types & related patterns:

- type checkers, such as [mypy](https://mypy-lang.org/)

- Value Object pattern

- Pydantic

### Monitoring

- classic metrics on e.g. Prometheus

- Distributed Tracing with e.g. [Open Telemetry](https://opentelemetry.io/)

…but the most important ingredient is your software development process.

## Other links

- [pylyzer](https://github.com/mtshiba/pylyzer) (yup, another Rust-powered super-fast code analysis tool)

- [Goodhart Law Isn’t As Useful As You Might Think](https://commoncog.com/goodharts-law-not-useful/) - what can happen when some metric is pressurized and what to do then

