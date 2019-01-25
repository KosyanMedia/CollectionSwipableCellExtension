Pod::Spec.new do |s|
  s.name = 'CollectionSwipableCellExtension'
  s.version = '0.0.3'
  s.license = 'MIT'
  s.summary = 'It is the extension for UICollectionView and UITableView which appends buttons to a cell and shows them on cell swiping.'
  s.homepage = 'https://github.com/KosyanMedia/CollectionSwipableCellExtension'
  s.authors = { 'KosyanMedia' => 'info@jetradar.com' }
  s.source = { :git => 'https://github.com/KosyanMedia/CollectionSwipableCellExtension.git', :tag => s.version }

  s.swift_version = '4.2'
  s.ios.deployment_target = '8.0'

  s.source_files = 'Library/*.swift', 'Library/Private/*.swift'
end
