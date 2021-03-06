#pragma once

#include "std/string.hpp"
#include "std/vector.hpp"

#include "base/macros.hpp"

class FeatureType;

namespace ftypes
{
class BaseChecker;
}

namespace search
{
namespace v2
{
// This class is used to map feature types to a restricted set of
// different search classes (do not confuse these classes with search
// categories - they are completely different things).
class SearchModel
{
public:
  enum SearchType
  {
    // Low-level features such as amenities, offices, shops, buildings
    // without house number, etc.
    SEARCH_TYPE_POI = 0,

    // All features with set house number.
    SEARCH_TYPE_BUILDING = 1,

    SEARCH_TYPE_STREET = 2,

    // All low-level features except POI, BUILDING and STREET.
    SEARCH_TYPE_UNCLASSIFIED = 3,

    SEARCH_TYPE_VILLAGE = 4,
    SEARCH_TYPE_CITY = 5,
    SEARCH_TYPE_STATE = 6,  // US or Canadian states
    SEARCH_TYPE_COUNTRY = 7,

    SEARCH_TYPE_COUNT
  };

  static SearchModel const & Instance();

  SearchType GetSearchType(FeatureType const & feature) const;

private:
  SearchModel() = default;

  DISALLOW_COPY_AND_MOVE(SearchModel);
};

string DebugPrint(SearchModel::SearchType type);
}  // namespace v2
}  // namespace search
