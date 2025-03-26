--- 
layout: post
title: Four strategies to automate tests with 3rd party APIs used in the application
date: 2023-04-27 18:14:19 +0100
published: true 
categories: []
tags: []
lang: 
---

## Acceptance testing

One of the most valuable kinds of tests are the acceptance tests. They are written from a perspective of an end-user or a particular stakeholder. Their goal is to verify if the system behaves as it should from their viewpoint.

They are tests I start with, often coming up with testing scenarios long before I write any code. Ideally, I put some in a task before I start working on them.

Implementation-wise, my first approach is to automate acceptance tests at the level of the API. It’s far more stable and faster than doing the same thing via UI.

## The problem with acceptance testing and 3rd party vendors

Nowadays there are plenty of 3rd party vendors that offer services we can leverage in the projects. For example, payment services.

For many reasons, we may not use these services in acceptance tests.

### Slow

Calling external APIs may simply be slow due to network overhead. And we don’t like slow test suites my precious, oh we despise them.

### Unstable

External APIs can also fail randomly. We hate randomly failing test suites even more than slow ones.

### No test API

Sometimes providers offer a staging or test version of their API we can write tests against. If it is solid and future-complete, it’s great. Unfortunately, it’s rarely the case.

If the test API is not available at all we may try to use the production one. However, we still have to make sure it won’t affect our production system. Sometimes, even that is not feasible due to e.g. pricing of the production API of the provider.

### Hard to put the external system in a desired state

While we can easily control our database, we often have little control over the external system we integrate with. If the only way we can put it in a desired state is via a series of API calls, that’s very limiting from the perspective of writing acceptance tests.

## Strategy one - Gateway pattern

The first approach is to build a layer of abstraction over 3rd party API using [Gateway](https://martinfowler.com/articles/gateway-pattern.html) design pattern.

### Gateway pattern - implementation

Instead of calling API (or using SDK) directly here and there…

```python
    httpx.post("https://example.tech/payment-cards", json={
        "card_number": payload.card_number,
        "names": payload.names,
        "cvc": payload.cvc,
        "user_id": user_id,
    })
```

…we wrap it in a class / few classes / functions…

```python
    class PaymentsGateway:
        def store_payment_card(self, ...) -> None:
            httpx.post("https://example.tech/payment-cards", json={
                "card_number": dto.card_number,
                "names": dto.names,
                "cvc": dto.cvc,
                "user_id": dto.user_id,
            })
```

### Gateway pattern - testing

In our acceptance tests, we use stubs or mocks instead of Gateway.

```python
    # use as mock
    payments_mock = Mock(spec_set=PaymentsGateway)
    
    service = Service(payments_gateway=payments_mock)
    service.do_the_work()
    
    payments_mock.store_payment_card.assert_called_once_with()
    
    
    # use as stub
    payments_stub = Mock(
        spec_set=PaymentsGateway,
        get_cards=Mock(return_value=[])
    )
    
    other_service = OtherService(payments_gateway=payments_stub)
    result = other_service.cards()
    
    
    assert result == []
```

## Strategy two - specialized mocking libraries

Approach with Gateway is handy in acceptance tests, but naturally doesn’t deal with testing Gateway itself. Here, we need another approach. One of them might be using specialized mocking libraries.

For httpx there’s [pytest\_httpx](https://colin-b.github.io/pytest_httpx/) (slightly modified example comes from docs):

```python
    def test_something(httpx_mock):
        httpx_mock.add_response(url="https://test_url")
    
        with httpx.Client() as client:
            response = client.get("https://test_url")
```

For requests, there are… [responses](https://pypi.org/project/responses/) (I always liked the pun in the name! - slightly modified example comes from the docs):

```python
    import responses
    import requests
    
    
    @responses.activate
    def test_simple():
        rsp = responses.Response(
            method="PUT",
            url="http://example.com",
        )
        responses.add(rsp)
    
        response = requests.put("http://example.com")
    
        assert response.status_code == 200
        assert response.request.method == "PUT"
```

…and for aiohttp there are [aioresponses](https://github.com/pnuckowski/aioresponses) (example from the docs):

```python
    import aiohttp
    import asyncio
    from aioresponses import aioresponses
    
    @aioresponses()
    def test_request(mocked):
        loop = asyncio.get_event_loop()
        mocked.get('http://example.com', status=200, body='test')
        session = aiohttp.ClientSession()
        resp = loop.run_until_complete(session.get('http://example.com'))
    
        assert resp.status == 200
        mocked.assert_called_once_with('http://example.com')
```

## Strategy three - recording responses and replaying them with vcr.py

The previous approach with pytest\_httpx/responses/aioresponses assumes you can get the actual data API returns and put it in the tests.

This relies on you being careful which in short, is far from ideal. [vcr.py](https://vcrpy.readthedocs.io/en/latest/) takes another approach_._ At first call, requests are really sent to the 3rd party API but the responses are saved in a file (so-called cassette in vcr.py’s terminology). Then, on subsequent test runs no requests are sent and responses are read from the file.

Example from the [docs](https://vcrpy.readthedocs.io/en/latest/usage.html):

```python
    import vcr
    import urllib
    
    @vcr.use_cassette('fixtures/vcr_cassettes/synopsis.yaml')
    def test_iana():
        response = urllib.request.urlopen('http://www.iana.org/domains/reserved').read()
        assert 'Example domains' in response
```

Of course, this works fine as long as we don’t change the way we use the API or the API itself doesn’t change. But that’s a trade-off of this solution.

As a side note, it’s worth to implement filtering out sensitive data from requests, e.g. authorization headers. [This is supported in the library](https://vcrpy.readthedocs.io/en/latest/advanced.html#filter-sensitive-data-from-the-request).

[A similar feature was added to responses library](https://pypi.org/project/responses/#record-responses-to-files) some time ago. I can’t tell anything about its maturity, though - I’ve only used vcr.py. The latter is rock-solid and more than sufficient for most cases I can imagine.

## Strategy four - using specialized services

Another approach is to use mock servers. These are standalone processes that can be run e.g. in containers and can be “taught” how to respond to specific requests.

Examples of such services are [smocker](https://smocker.dev/) or [wiremock](https://wiremock.org/).

Using them looks as follows:

- run the API mocking service

- configure a service using API or config files (if they are supported in a given tool)

- run tests in a reconfigured application so it calls mocking service

- a) verify if API mocking service was called as expected if you use API mocking service as mock

- b) verify the response or state of your application if you use API mocking service as stub

In this approach, your application sends actual requests.

This solution is a bit more difficult to get right than mocking clients (i.e. pytest\_httpx, responses or aioresponses). It’s as reliable as that solution and equally hard (or easy…) to maintain.

## Conclusion

Using 3rd party APIs doesn’t mean you can’t test your application.

With a sufficient level of complexity, I recommend using the Gateway pattern in acceptance tests + any of the other three approaches for the testing Gateway itself.

That’s the approach I personally use. For context, I work mostly for & with product companies. As usual, one need to play around with possible solutions and try to find the one they feel the most comfortable with.

If your Python program is simpler, then just choose one of the last three approaches.

