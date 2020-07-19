//
//  CustomeCollectionViewFlowLayout.swift
//  Shinsi2
//
//  Created by Tokinogaki on 5/7/20.
//  Copyright © 2020 PowHu Yang. All rights reserved.
//

import UIKit

private let defaultColumnCout: Int = 3

@objc protocol CustomeCollectionViewFlowLayoutDelegate {
    func collectionViewFlowLayout(_ layout: CustomeCollectionViewFlowLayout, indexPath: IndexPath, heightInWidth width: CGFloat) -> CGFloat

    func numberOfColumn(in collectionViewFlowLayout: CustomeCollectionViewFlowLayout) -> Int
}

class CustomeCollectionViewFlowLayout: UICollectionViewFlowLayout {
    weak var delegate: CustomeCollectionViewFlowLayoutDelegate?
    
    let attributesArray = NSMutableArray()
    var heightArray = [CGFloat]()
    
    private var columnCount: Int {
        let columnCout = self.delegate?.numberOfColumn(in: self)
        return columnCout ?? defaultColumnCout
    }
    
    override func prepare() {
        attributesArray.removeAllObjects()
        heightArray.removeAll()
        for _ in 0 ..< self.columnCount {
            heightArray.append(sectionInset.top)
        }
        let count = self.collectionView?.numberOfItems(inSection: 0)
        for i in 0 ..< count! {
            let index = IndexPath(item: i, section: 0)
            let attributes = layoutAttributesForItem(at: index)
            attributesArray.add(attributes!)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        let collectionViewWidth = self.collectionView?.bounds.size.width
        let width = (collectionViewWidth! - sectionInset.left - sectionInset.right - (CGFloat(minimumInteritemSpacing - 1) * minimumInteritemSpacing)) / CGFloat(minimumInteritemSpacing)
        let height = self.delegate?.collectionViewFlowLayout(self, indexPath: indexPath, heightInWidth: width)
        var minHeight = heightArray[0]
        var minIdex = 0
        for i in ((1 ..< columnCount).filter { minHeight > heightArray[$0] }) {
            minHeight = heightArray[i]
            minIdex = i
        }
        let x = sectionInset.left + CGFloat(minIdex) * (width + minimumInteritemSpacing)
        var y = minHeight
        if y != sectionInset.top {
            y = minHeight + minimumLineSpacing
        }
        heightArray[minIdex] = y + height!
        attributes!.frame = CGRect(x: x, y: y, width: width, height: height!)
        return attributes
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesArray as? [UICollectionViewLayoutAttributes]
    }

    override var collectionViewContentSize: CGSize {
        var maxHeight  = heightArray[0]
        for i in ((1 ..< columnCount).filter { maxHeight < heightArray[$0] }) {
            maxHeight    = heightArray[i]
        }
        
        return CGSize(width: 0, height: maxHeight)
    }
   
}
