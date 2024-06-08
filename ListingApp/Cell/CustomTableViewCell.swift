//
//  CustomTableViewCell.swift
//  ListingApp
//
//  Created by Mine Rala on 7.05.2024.
//

import UIKit

// MARK: - Class Bone
final class CustomTableViewCell: UITableViewCell {
    // MARK: Properties
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.textAlignment = .left
        label.font = UIFont(name: "Montserrat-Regular", size: 16)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}

// MARK: - Configure
extension CustomTableViewCell {
    private func configureCell() {
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -10 * 2),
            titleLabel.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -10 * 2)
        ])
    }
}

// MARK: - Set
extension CustomTableViewCell {
    public func setCell(person: Model) {
        titleLabel.text = person.name + " (\(person.id))"
    }
}
