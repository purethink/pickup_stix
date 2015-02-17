class Java::JavaxXmlNamespace::QName
  def initialize(*args)
    if args.length == 1 && args.first.kind_of?(Hash)
      super(args[0]['namespace'] || "", args[0]['local_part'] || "", args[0]['prefix'] || "")
    else
      super
    end
  end
end
