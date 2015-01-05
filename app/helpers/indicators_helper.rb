module IndicatorsHelper
  def indicator_type(indicator)
    if indicator.types.length > 0
      indicator.types.map(&:value).join(", ")
    else
      "Generic Indicator"
    end
  end
end
