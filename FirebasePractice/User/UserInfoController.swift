//
//  UserInfoController.swift
//  FirebasePractice
//
//  Created by Ray on 2018/7/10.
//  Copyright © 2018 ycray.net. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class UserInfoController: UITableViewController {

    @IBOutlet weak var closeBarBtn: UIBarButtonItem!
    @IBOutlet weak var portraitBtn: UIButton!
    @IBOutlet weak var emailLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var genderLbl: UILabel!
    @IBOutlet weak var ageLbl: UILabel!
    @IBOutlet weak var signOutBtn: UIButton!

    fileprivate var editController: UserInfoEditController?
    fileprivate let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavbar()
        maskPortrait()
        rx()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "segue_userInfo_startEdit":
            editController = segue.destination as? UserInfoEditController
        default:
            break
        }
    }
}

// MARK: - Private Methods

extension UserInfoController {

    func setupNavbar() {
        navigationController?.navigationBar.backIndicatorImage = UIImage()
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        navigationItem.backBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_arrowLeft"), style: .plain, target: nil, action: nil)
    }

    func maskPortrait() {

        //portraitBtn.clipsToBounds = false
        let bounds = portraitBtn.bounds
        let maskLayer = CAShapeLayer()
        let maskPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width)

        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = UIColor.black.cgColor
        portraitBtn.layer.mask = maskLayer

        /*
        let rimLayer = CAShapeLayer()
        let rimPath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.width)
        let rimPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: bounds.origin.x - 2, y: bounds.origin.x - 2),
                                                      size: CGSize(width: bounds.width + 4, height: bounds.height + 4)),
                                   cornerRadius: bounds.width + 4)
        rimLayer.path = rimPath.cgPath
        rimLayer.fillColor = UIColor.clear.cgColor
        rimLayer.strokeColor = UIColor.red.cgColor
        rimLayer.lineWidth = 1.5
        */
    }

    func rx() {
        let vm = UserInfoViewModel(input: (itemOnSelect: tableView.rx.itemSelected.asDriver(),
                                           signOutOnTap: signOutBtn.rx.tap.asDriver()))

        vm.userInfoDrv
            .drive(onNext: { (userInfo) in
                self.hideLoadingHud()
                guard let user = userInfo else { return }
                self.emailLbl.text = user.email
                self.usernameLbl.text = (user.name.isEmpty) ? "n/a" : user.name
                self.genderLbl.text = user.gender.description
                self.ageLbl.text = user.age.description
                //self.portraitBtn.setImage(user.portrait ?? UIImage(named: "ic_portrait"), for: .normal)
            })
            .disposed(by: disposeBag)

        vm.progressingDrv
            .drive(onNext: { (flag) in
                if flag {
                    self.showLoadingHud()
                }
            })
            .disposed(by: disposeBag)

        vm.userInfoErrDrv
            .flatMap({ (error) -> Driver<Int> in
                return self.showAlert(message: error).asDriver(onErrorDriveWith: Driver.never())
            })
            .map({ _ in
                self.dismiss(animated: true, completion: nil)
            })
            .drive()
            .disposed(by: disposeBag)

        vm.editingTypeDrv
            .asObservable()
            .subscribe(onNext: { (editType) in
                guard let type = editType else { return }
                self.performSegue(withIdentifier: "segue_userInfo_startEdit", sender: nil)
                self.editController?.loadView()
                self.editController?.startEditing(ofType: type)
            })
            .disposed(by: disposeBag)

        vm.userSignedOut
            .drive()
            .disposed(by: disposeBag)

        closeBarBtn.rx.tap
            .asObservable()
            .subscribe(onNext: { _ in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
    }
}

// MARK: - UITableViewDelegate

extension UserInfoController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
