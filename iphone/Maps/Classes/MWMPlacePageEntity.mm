#import "MWMFrameworkListener.h"
#import "MWMPlacePageEntity.h"
#import "MWMPlacePageViewManager.h"
#import "MapViewController.h"
#import "DataConverter.h"

#include "Framework.h"

#include "platform/measurement_utils.hpp"
#include "platform/mwm_version.hpp"

using feature::Metadata;

extern NSString * const kUserDefaultsLatLonAsDMSKey = @"UserDefaultsLatLonAsDMS";

namespace
{

NSUInteger gMetaFieldsMap[MWMPlacePageCellTypeCount] = {};

void putFields(NSUInteger eTypeValue, NSUInteger ppValue)
{
  gMetaFieldsMap[eTypeValue] = ppValue;
  gMetaFieldsMap[ppValue] = eTypeValue;
}

void initFieldsMap()
{
  putFields(Metadata::FMD_URL, MWMPlacePageCellTypeURL);
  putFields(Metadata::FMD_BOOKING_URL, MWMPlacePageCellTypeBooking);
  putFields(Metadata::FMD_WEBSITE, MWMPlacePageCellTypeWebsite);
  putFields(Metadata::FMD_PHONE_NUMBER, MWMPlacePageCellTypePhoneNumber);
  putFields(Metadata::FMD_OPEN_HOURS, MWMPlacePageCellTypeOpenHours);
  putFields(Metadata::FMD_EMAIL, MWMPlacePageCellTypeEmail);
  putFields(Metadata::FMD_POSTCODE, MWMPlacePageCellTypePostcode);
  putFields(Metadata::FMD_INTERNET, MWMPlacePageCellTypeWiFi);
  putFields(Metadata::FMD_CUISINE, MWMPlacePageCellTypeCuisine);

  ASSERT_EQUAL(gMetaFieldsMap[Metadata::FMD_URL], MWMPlacePageCellTypeURL, ());
  ASSERT_EQUAL(gMetaFieldsMap[Metadata::FMD_BOOKING_URL], MWMPlacePageCellTypeBooking, ());
  ASSERT_EQUAL(gMetaFieldsMap[MWMPlacePageCellTypeURL], Metadata::FMD_URL, ());
  ASSERT_EQUAL(gMetaFieldsMap[MWMPlacePageCellTypeBooking], Metadata::FMD_BOOKING_URL, ());
  ASSERT_EQUAL(gMetaFieldsMap[Metadata::FMD_WEBSITE], MWMPlacePageCellTypeWebsite, ());
  ASSERT_EQUAL(gMetaFieldsMap[MWMPlacePageCellTypeWebsite], Metadata::FMD_WEBSITE, ());
  ASSERT_EQUAL(gMetaFieldsMap[Metadata::FMD_POSTCODE], MWMPlacePageCellTypePostcode, ());
  ASSERT_EQUAL(gMetaFieldsMap[MWMPlacePageCellTypePostcode], Metadata::FMD_POSTCODE, ());
  ASSERT_EQUAL(gMetaFieldsMap[Metadata::FMD_MAXSPEED], 0, ());
}
} // namespace

@implementation MWMPlacePageEntity
{
  MWMPlacePageCellTypeValueMap m_values;
  place_page::Info m_info;
  m2::PointD m_tripfingerMercator;
  BookmarkAndCategory m_tripfingerBac;
}

- (instancetype)initWithInfo:(const place_page::Info &)info
{
  self = [super init];
  if (self)
  {
    m_info = info;
    initFieldsMap();
    [self config];
  }
  return self;
}

- (instancetype)initWithEntity:(TripfingerEntity*)entity
{
  self = [super init];
  if (self)
  {
    self.tripfingerEntity = entity;
    initFieldsMap();
    self.title = entity.name;
    self.address = entity.address;
    if (entity.email != nil) {
      [self setMetaField:gMetaFieldsMap[Metadata::FMD_EMAIL] value:[entity.email UTF8String]];
    }
    if (entity.website != nil) {
      if ([entity.website hasPrefix:@"http://www.booking.com"]) {
        [self setMetaField:gMetaFieldsMap[Metadata::FMD_BOOKING_URL] value:[entity.website UTF8String]];
      } else {
        [self setMetaField:gMetaFieldsMap[Metadata::FMD_URL] value:[entity.website UTF8String]];
      }
    }
    if (entity.phone != nil) {
      [self setMetaField:gMetaFieldsMap[Metadata::FMD_PHONE_NUMBER] value:[entity.phone UTF8String]];
    }
    if (entity.openingHours != nil) {
      [self setMetaField:gMetaFieldsMap[Metadata::FMD_OPEN_HOURS] value:[entity.openingHours UTF8String]];
    }
//    [self setMetaField:gMetaFieldsMap[Metadata::FMD_CUISINE] value:string("Bakst")];

    self.bookmarkTitle = entity.name;
    self.bookmarkDescription = nil;
    _isHTMLDescription = NO;
    
    m_tripfingerMercator = MercatorBounds::FromLatLon(self.tripfingerEntity.lat, self.tripfingerEntity.lon);
    TripfingerMark mark = [DataConverter entityToMark:self.tripfingerEntity];
    m_tripfingerBac = GetFramework().FindBookmark(&mark);
  }
  return self;
}


- (void)config
{
  [self configureDefault];

  if (m_info.IsFeature())
    [self configureFeature];
  if (m_info.IsBookmark())
    [self configureBookmark];
}

- (void)setMetaField:(NSUInteger)key value:(string const &)value
{
  NSAssert(key >= Metadata::FMD_COUNT, @"Incorrect enum value");
  MWMPlacePageCellType const cellType = static_cast<MWMPlacePageCellType>(key);
  if (value.empty())
    m_values.erase(cellType);
  else
    m_values[cellType] = value;
}

- (void)configureDefault
{
  self.title = @(m_info.GetTitle().c_str());
  self.address = @(m_info.GetAddress().c_str());
}

- (void)configureFeature
{
  // Category can also be custom-formatted, please check m_info getters.
  self.category = @(m_info.GetSubtitle().c_str());
  // TODO(Vlad): Refactor using osm::Props instead of direct Metadata access.
  feature::Metadata const & md = m_info.GetMetadata();
  for (auto const type : md.GetPresentTypes())
  {
    switch (type)
    {
      case Metadata::FMD_URL:
      case Metadata::FMD_BOOKING_URL:
      case Metadata::FMD_WEBSITE:
      case Metadata::FMD_PHONE_NUMBER:
      case Metadata::FMD_OPEN_HOURS:
      case Metadata::FMD_EMAIL:
      case Metadata::FMD_POSTCODE:
        [self setMetaField:gMetaFieldsMap[type] value:md.Get(type)];
        break;
      case Metadata::FMD_INTERNET:
        [self setMetaField:gMetaFieldsMap[type] value:L(@"WiFi_available").UTF8String];
        break;
      default:
        break;
    }
  }
}

- (void)configureBookmark
{
  auto const bac = m_info.GetBookmarkAndCategory();
  BookmarkCategory * cat = GetFramework().GetBmCategory(bac.first);
  BookmarkData const & data = static_cast<Bookmark const *>(cat->GetUserMark(bac.second))->GetData();

  self.bookmarkTitle = @(data.GetName().c_str());
  self.bookmarkCategory = @(cat->GetName().c_str());
  string const & description = data.GetDescription();
  self.bookmarkDescription = @(description.c_str());
  _isHTMLDescription = strings::IsHTML(description);
  self.bookmarkColor = @(data.GetType().c_str());
}

- (void)toggleCoordinateSystem
{
  NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
  [ud setBool:![ud boolForKey:kUserDefaultsLatLonAsDMSKey] forKey:kUserDefaultsLatLonAsDMSKey];
  [ud synchronize];
}

#pragma mark - Getters

- (NSString *)getCellValue:(MWMPlacePageCellType)cellType
{
  bool const isNewMWM = version::IsSingleMwm(GetFramework().Storage().GetCurrentDataVersion());
  switch (cellType)
  {
    case MWMPlacePageCellTypeName:
      return self.title;
    case MWMPlacePageCellTypeCoordinate:
      return [self coordinate];
    case MWMPlacePageCellTypeBookmark:
      if ([self isTripfinger]) {
        return self.tripfingerEntity.liked ? @"" : nil;
      } else {
        return m_info.IsBookmark() ? @"" : nil;
      }
    case MWMPlacePageCellTypeInfo:
      return [self isTripfinger] ? @"": nil;
    case MWMPlacePageCellTypeEditButton:
      // TODO(Vlad): It's a really strange way to "display" cell if returned text is not nil.
      return nil; //@"";
    case MWMPlacePageCellTypeReportButton:
      return nil; // m_info.IsFeature() && isNewMWM ? @"" : nil;
    default:
    {
      auto const it = m_values.find(cellType);
      BOOL const haveField = (it != m_values.end());
      return haveField ? @(it->second.c_str()) : nil;
    }
  }
}

- (place_page::Info const &)info
{
  return m_info;
}

- (FeatureID const &)featureID
{
  return m_info.GetID();
}

- (BOOL)isMyPosition
{
  return m_info.IsMyPosition();
}

- (BOOL)isBookmark
{
  if ([self isTripfinger]) {
    return self.tripfingerEntity.liked;
  } else {
    return m_info.IsBookmark();
  }
}

- (BOOL)isApi
{
  return m_info.HasApiUrl();
}

- (BOOL)isTripfinger
{
  return self.tripfingerEntity != nil;
}

- (ms::LatLon)latlon
{
  if ([self isTripfinger]) {
    return ms::LatLon(self.tripfingerEntity.lat, self.tripfingerEntity.lon);
  } else {
    return m_info.GetLatLon();
  }
}

- (m2::PointD const &)mercator
{
  if ([self isTripfinger]) {
    return m_tripfingerMercator;
  } else {
    return m_info.GetMercator();
  }
}

- (NSString *)apiURL
{
  return @(m_info.GetApiUrl().c_str());
}

- (string)titleForNewBookmark
{
  if ([self isTripfinger]) {
    return [self.title UTF8String];
  } else {
    return m_info.FormatNewBookmarkName();
  }
}

- (NSString *)coordinate
{
  BOOL const useDMSFormat =
      [[NSUserDefaults standardUserDefaults] boolForKey:kUserDefaultsLatLonAsDMSKey];
  ms::LatLon const latlon = self.latlon;
  return @((useDMSFormat ? MeasurementUtils::FormatLatLon(latlon.lat, latlon.lon)
                         : MeasurementUtils::FormatLatLonAsDMS(latlon.lat, latlon.lon, 2)).c_str());
}

#pragma mark - Bookmark editing

- (void)setBac:(BookmarkAndCategory)bac
{
  if ([self isTripfinger]) {
    m_tripfingerBac = bac;
  } else {
    m_info.m_bac = bac;
  }
}

- (BookmarkAndCategory)bac
{
  if ([self isTripfinger]) {
    return m_tripfingerBac;
  } else {
    return m_info.GetBookmarkAndCategory();
  }
}

- (NSString *)bookmarkCategory
{
  if (!_bookmarkCategory)
  {
    Framework & f = GetFramework();
    BookmarkCategory * category = f.GetBmCategory(f.LastEditedBMCategory());
    _bookmarkCategory = @(category->GetName().c_str());
  }
  return _bookmarkCategory;
}

- (NSString *)bookmarkDescription
{
  if (!_bookmarkDescription)
    _bookmarkDescription = @"";
  return _bookmarkDescription;
}

- (NSString *)bookmarkColor
{
  if (!_bookmarkColor)
  {
    Framework & f = GetFramework();
    string type = f.LastEditedBMType();
    _bookmarkColor = @(type.c_str());
  }
  return _bookmarkColor;
}

- (NSString *)bookmarkTitle
{
  if (!_bookmarkTitle)
    _bookmarkTitle = self.title;
  return _bookmarkTitle;
}

- (void)synchronize
{
  Framework & f = GetFramework();
  BookmarkCategory * category = f.GetBmCategory(self.bac.first);
  if (!category)
    return;

  {
    BookmarkCategory::Guard guard(*category);
    Bookmark * bookmark = static_cast<Bookmark *>(guard.m_controller.GetUserMarkForEdit(self.bac.second));
    if (!bookmark)
      return;
  
    if (self.bookmarkColor)
      bookmark->SetType(self.bookmarkColor.UTF8String);

    if (self.bookmarkDescription)
    {
      string const description(self.bookmarkDescription.UTF8String);
      _isHTMLDescription = strings::IsHTML(description);
      bookmark->SetDescription(description);
    }

    if (self.bookmarkTitle)
      bookmark->SetName(self.bookmarkTitle.UTF8String);
  }
  
  category->SaveToKMLFile();
}

@end
