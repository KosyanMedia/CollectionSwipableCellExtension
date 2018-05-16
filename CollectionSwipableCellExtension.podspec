Pod::Spec.new do |s|

  s.name         = "CollectionSwipableCellExtension"
  s.version      = "0.0.1"
  s.summary      = "Swipable buttons for UICollectionView and UITableView"

  s.description  = <<-DESC
  The extension for UICollectionView and UITableView which appends buttons to a cell are shown on cell swiping. Also supports swipe to delete gesture.
                   DESC

  s.homepage     = "https://github.com/KosyanMedia/CollectionSwipableCellExtension"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Dmitry Ryumin" => "dmitry.glassoff@gmail.com" }

  s.platform     = :ios, "8.0"

  s.swift_version = "4.1"

  s.source       = { :git => "https://github.com/KosyanMedia/CollectionSwipableCellExtension.git", :tag => "#{s.version}" }

  s.source_files  = "Library", "Library/**/*.{swift}"

end
