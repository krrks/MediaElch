#include "test/test_helpers.h"

#include "scrapers/tmdb/TmdbApi.h"

#include <QUrlQuery>

using namespace mediaelch;
using namespace mediaelch::scraper;

namespace {

int queryItemCount(const QUrl& url, const QString& key)
{
    const QUrlQuery query(url);
    int count = 0;
    for (const auto& item : query.queryItems()) {
        if (item.first == key) {
            ++count;
        }
    }
    return count;
}

} // namespace

TEST_CASE("TMDb movie search URL does not contain duplicate query parameters", "[scrapers][tmdb][regression]")
{
    // Regression test for https://github.com/Komet/MediaElch/issues/1992
    // TMDb answers requests with duplicate parameters with HTTP 400, which was
    // shown to users as a generic "network error".
    const TmdbApi api;
    const Locale locale = Locale::English;

    SECTION("include_adult is only added once if passed as a parameter")
    {
        const QUrl url = api.getMovieSearchUrl("Some Movie",
            locale,
            false,
            TmdbApi::UrlParameterMap{{TmdbApi::ApiUrlParameter::INCLUDE_ADULT, "false"}});

        CHECK(queryItemCount(url, "include_adult") == 1);
    }

    SECTION("include_adult and year are each only added once")
    {
        const QUrl url = api.getMovieSearchUrl("Some Movie",
            locale,
            true,
            TmdbApi::UrlParameterMap{{TmdbApi::ApiUrlParameter::INCLUDE_ADULT, "true"},
                {TmdbApi::ApiUrlParameter::YEAR, "1999"}});

        CHECK(queryItemCount(url, "include_adult") == 1);
        CHECK(queryItemCount(url, "year") == 1);
    }

    SECTION("include_adult is added once without additional parameters")
    {
        const QUrl url = api.getMovieSearchUrl("Some Movie", locale, false, {});

        CHECK(queryItemCount(url, "include_adult") == 1);
    }
}
