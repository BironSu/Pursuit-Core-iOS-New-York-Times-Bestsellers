//
//  BestSellerViewController.swift
//  NYTBestsellers
//
//  Created by Biron Su on 1/25/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import UIKit

class BestSellerViewController: UIViewController {

    let bestSellerView = BestSellerView()
    var genreList = [ListNames]() {
        didSet {
            DispatchQueue.main.async {
                self.bestSellerView.pickerView.reloadAllComponents()
            }
        }
    }
    var bookList = [Book]() {
        didSet {
            DispatchQueue.main.async {
                self.bestSellerView.collectionView.reloadData()
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bestSellerView.collectionView.dataSource = self
        bestSellerView.collectionView.delegate = self
        bestSellerView.pickerView.dataSource = self
        bestSellerView.pickerView.delegate = self
        view.addSubview(bestSellerView)
        navigationItem.title = "Best Sellers"
        getGenre()
        checkDefaultSearchSettings()
    }
    override func viewWillAppear(_ animated: Bool) {
        checkDefaultSearchSettings()
    }

    func getGenre() {
        NYTAPIClient.getGenre { (error, data) in
            if let error = error {
                print("Error on BSVC:getGenre \(error)")
            } else if let data = data {
                self.genreList = data
            }
        }
    }
    func getBooks(keyword: String) {
        NYTAPIClient.getBooks(keyword: keyword) { (error, data) in
            if let error = error {
                print("Error on BSVC: getBooks \(error)")
            } else if let data = data {
                self.bookList = data
            }
        }
    }
    func checkDefaultSearchSettings() {
        if let defaultKeyword = UserDefaults.standard.object(forKey: "Default Genre") as? String {
            getBooks(keyword: defaultKeyword.replacingOccurrences(of: " ", with: "-"))
        }
    }
}

extension BestSellerViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BestSellerCell", for: indexPath) as? BestSellerCollectionViewCell else {return UICollectionViewCell()}
        let cellToSet = bookList[indexPath.row]
        cell.bookText.text = cellToSet.book_details[0].description
        cell.bookLabel.text = "\(cellToSet.weeks_on_list) weeks on best seller"
        GoogleAPIClient.getImage(keyword: cellToSet.book_details[0].primary_isbn13) { (error, image) in
            if let _ = error {
                DispatchQueue.main.async {
                    cell.bookImage.image = UIImage(named: "book")
                }
            } else if let image = image {
                ImageHelper.fetchImageFromNetwork(urlString: image[0].volumeInfo.imageLinks.smallThumbnail.absoluteString, completion: { (error, smallImage) in
                    if let error = error {
                        print("Small Image error \(error)")
                    } else if let smallImage = smallImage {
                        DispatchQueue.main.async {
                            cell.bookImage.image = smallImage
                        }
                    }
                })
            }
        }
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detail = DetailViewController.init(book: bookList[indexPath.row])
        self.navigationController?.pushViewController(detail, animated: true)
    }
}
extension BestSellerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genreList.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genreList[row].list_name
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        getBooks(keyword: genreList[row].list_name.replacingOccurrences(of: " ", with: "-"))
    }
}
