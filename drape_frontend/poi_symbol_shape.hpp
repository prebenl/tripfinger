#pragma once

#include "map_shape.hpp"
#include "shape_view_params.hpp"

namespace df
{

class PoiSymbolShape : public MapShape
{
public:
  PoiSymbolShape(m2::PointD const & mercatorPt, PoiSymbolViewParams const & params);

  virtual void Draw(RefPointer<Batcher> batcher, RefPointer<TextureSetHolder> textures) const;

private:
  m2::PointD const m_pt;
  PoiSymbolViewParams const m_params;
};

} // namespace df

