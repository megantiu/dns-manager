# dns-manager

`dns-manager` is a Rails 5.2 application allowing you to create DNS zones and records via the [NS1 API](https://ns1.com/).

## Background

This application was created in a few hours as a challenge for a previous company. I am choosing to use this app as a code sample because it's a representative selection of my work under a short time frame, as well as for the way I prefer to communicate about the software I make and the choices I make along the way. Additionally, this exercise covers working with third-party APIs, code organization, testing, error handling, RESTful operations, and more.

The original prompt was to create a minimum viable web application that provides a simple user interface for managing DNS records using the NS1 API. It directly correlates with the [NS1 domain concepts](https://ns1.com/api) of the Zone (like a domain, e.g. `megantiu.com`) and Records (individual DNS records, like a TXT or A record).

## System Requirements

In order to get this project up and running, you'll need the following:

* Ruby 2.5.x+
* PostgreSQL
  * (This app was created with 9.4 because that's evidently what I had on my personal computer.)
* NS1 API credentials

Note: I deliberately skipped adding Webpacker/Javascript to this application (they come with Rails 6 by default) in order to reduce system requirements. This application is only meant to be an MVP of the DNS service, so a fully interactive UI isn't necessary at this phase of the project.

## Setup

To get going, clone this repository, then run:

```
bin/setup
```

This will install the necessary dependencies and prepare your database.

Next, copy the `.env` template:

```
cp .env.example .env
```

and, using your favorite text editor, add your NS1 API key to the new `.env` file.

## Testing

To run the test suite, run:

```
bundle exec rake
```

This application uses RSpec for testing (this is my Ruby testing framework of choice).

## What's in here?

* UI
    * [`/zones` list](https://github.com/megantiu/dns-manager/blob/master/app/views/zones/index.html.erb)
        * Create/Destroy buttons
        * [The show page](https://github.com/megantiu/dns-manager/blob/master/app/views/zones/show.html.erb) allows you to CRUD Records
            * Users [can specify](https://github.com/megantiu/dns-manager/blob/master/app/views/zones/_form.html.erb) TTL and Record content
* [Zone table](https://github.com/megantiu/dns-manager/blob/master/app/models/zone.rb)
    * can `has_many` records
* [Record table](https://github.com/megantiu/dns-manager/blob/master/app/models/record.rb)
    * `has_one` domain
* [NS1 API client](https://github.com/megantiu/dns-manager/tree/master/app/lib)

## Development Process

### Challenges
* Lack of familiarity with DNS principles
    * My work with DNS thus far has been pretty small and surface-level, so I'll admit that I sunk a bunch of time over the course of this exercise into understanding the different moving pieces (zones and the relationship to records, answers, etc.). On the plus side, I learned something! But on the down side, it meant I couldn't do as much with the project as I would've liked.

### Decisions
* Monolithic Rails app
    * The front-end and back-end are within the same Rails application.
    * I chose this direction for ease of creating the interface and reducing the upfront effort and complexity for an MVP.
    * If this were to become a bigger project and progress past the MVP stage, we could always extract a proper UI into a separate application, making this Rails app API-only. That approach would also allow it to be easy to expose the API for other direct consumers.
    * This is a decision, however, when making in a production codebase, I would take other people-focused factors into account, like preferences of the team, what the long-term vision of this part of the product/infrastructure is, skills/background of the team, etc.
* Organizing API requests
    * I used the Typhoeus gem because it provides easy stubbing for testing. It's also very performant, and can be adapted in the future to have parallel requests if this project were to scale.
    * I created a [base API class](https://github.com/megantiu/dns-manager/blob/master/app/lib/ns1.rb) to deal with the common knitty-gritty aspects of making API requests. Then, each object (Zone/Record) has [its own API client](https://github.com/megantiu/dns-manager/tree/master/app/lib/ns1). This pattern was influenced by the fact that I like to make API interfaces that are as easy to use and as clean as possible.
* Using the storage layer
    * I'm using a PostgreSQL database, which will store the necessary info from NS1 so we don't always have to rely on external web requests to fetch our data.
* NS1's impact on web requests
    * Currently, API requests to NS1 happen in real time in order to help prevent data from getting out of sync and to give immediate feedback to the user. This results in the following workflow:
        * If an API request fails, give an error message on the form and ask them to try again
        * Given more time, I would love to consider an asynchronous solution. This would be ideal if we make this application into a separate API. For now, however, since the front-end is coupled to the back-end, this made the most sense with the time I had.
    * Additionally, the user needs the nameservers to point their domain at. This information is only available with a successful response from NS1, so we want to wait until that information is available from NS1 before displaying a successful Zone creation message.
* Zone types
    * For simplicity, I chose only to focus on "standard" Zones. NS1 allows for linked and secondary Zones as well, but I wanted to keep this solution straightforward.
* Limited fields
    * I am limiting the amount of fields that a user can edit on a Zone and on a Record. This is partially due to simplicity so that there is less to account for during this MVP phase, but also partially because I do have a lack of familiarity with DNS conventions. Typically, I'd ask more questions to gather exactly what we as a business want the user to be able to do, but in this case, it seemed like it was up to me.

### Limitations/Opportunities
This includes all the things I would do different if I were to spend more time on this application!

* No editing Zones
    * Because I kept the Zone fields as simple as possible (and only stored the zone name), I didn't have anything else to edit on the Zone object. With more time, I would've added more fields for customization.
* Only allow certain Record types
    * A, AAAA, ALIAS, CNAME, NS, PTR, SPF, TXT
    * Other record types have more fields, which would require multiple other custom options. My version proves out the concept, though if I were to have more time, supporting other Record types is the first thing I'd like to do, along with validating the `rdata` based on the Record type.
* Validations
    * I would've liked to be able to validate the `rdata` based on a Record's type, but that would've been additional research time, whereas I wanted to focusing on building for this MVP.
* User Interface
    * Because the purpose of this exercise (the way I understood it) is to prove out the viability of the back-end functionality, I didn't want to sink any time into a flashy UI, so I used Rails' default scaffold styles. Of course, this is far from a pretty interface, so it would be nice to improve the UI in order to create a better user experience.
* Different domains for a Record
    * As of right now, this only supports a Record being at the root-level of a Zone (like at `megantiu.com` for a Zone of `megantiu.com`), another cut due to time. It would be nice to allow setting allowing a Record to be set at a subdomain, like test.megantiu.com. To do this, I'd add a `domain` column to the `records` table and add it as an input to the Record form.
* More helpful error messages
    * Currently, all of the error messages that display when an API request fails just ask the user to "try again". However, this isn't very helpful, so it would be nice to tell the user more about what is happening. This would've required more research into the different NS1 API error responses, which would take time I didn't have.
* Refactor
    * (There's some nested logic in the controllers, oof.)
    * I would've loved to get a lot of the logic for communicating with NS1 out of controllers and into models.

## Thank you!

Thanks for reading! I hope you have a great day.
