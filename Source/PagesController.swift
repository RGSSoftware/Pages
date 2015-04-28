import UIKit

@objc(HYPPagesControllerDelegate) public protocol PagesControllerDelegate {

  func pageViewController(pageViewController: UIPageViewController, setViewController viewController: UIViewController, atPage page: Int)
}

@objc(HYPPagesController) public class PagesController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

  struct Dimensions {
    static let bottomLineHeight: CGFloat = 1.0
    static let bottomLineSideMargin: CGFloat = 40.0
    static let bottomLineBottomMargin: CGFloat = 36.0
  }

  public var startPage = 0
  public var setNavigationTitle = true

  public var enableSwipe = true {
    didSet {
      toggle()
    }
  }

  public var showBottomLine = false {
    didSet {
      bottomLineView.hidden = !showBottomLine
    }
  }

  lazy var pages = Array<UIViewController>()

  public private(set) var currentIndex = 0

  public var pagesDelegate: PagesControllerDelegate?

  public private(set) var bottomLineView: UIView = {
    let view = UIView(frame: CGRectZero)
    view.setTranslatesAutoresizingMaskIntoConstraints(false)
    view.backgroundColor = UIColor.whiteColor()
    view.alpha = 0.4
    view.hidden = true
    return view
    }()

  public convenience init(_ pages: [UIViewController],
    transitionStyle: UIPageViewControllerTransitionStyle = .Scroll,
    navigationOrientation: UIPageViewControllerNavigationOrientation = .Horizontal,
    options: [NSObject : AnyObject]? = nil) {
      self.init(transitionStyle: transitionStyle,
        navigationOrientation: navigationOrientation,
        options: options)

      add(pages)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self

    view.addSubview(bottomLineView)
    addConstraints()
    view.bringSubviewToFront(bottomLineView)
    goTo(startPage)
  }
}

// MARK: Public methods
extension PagesController {

  public func goTo(index: Int) {
    if index >= 0 && index < pages.count {
      let direction: UIPageViewControllerNavigationDirection = (index > currentIndex) ? .Forward : .Reverse
      let viewController = pages[index]
      currentIndex = index
      setViewControllers([viewController],
        direction: direction,
        animated: true,
        completion: { [unowned self] finished in
          self.pagesDelegate?.pageViewController(self,
            setViewController: viewController,
            atPage: self.currentIndex)
        })
      if setNavigationTitle {
        title = viewController.title
      }
    }
  }

  public func next() {
    goTo(currentIndex + 1)
  }

  public func previous() {
    goTo(currentIndex - 1)
  }

  public func add(viewControllers: [UIViewController]) {
    for viewController in viewControllers {
      addViewController(viewController)
    }
  }
}

// MARK: UIPageViewControllerDataSource

extension PagesController {

  public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    let index = prevIndex(viewControllerIndex(viewController))
    return pages.at(index)
  }

  public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    let index: Int? = nextIndex(viewControllerIndex(viewController))
    return pages.at(index)
  }

  public func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
    return pages.count
  }

  public func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
    return currentIndex
  }

}

// MARK: UIPageViewControllerDelegate

extension PagesController {

  public func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {

    if let viewController = pendingViewControllers.first as? UIViewController,
      index = viewControllerIndex(viewController) {
        currentIndex = index

        if setNavigationTitle {
          title = viewController.title
        }
    }
  }

  public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
    previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
    if completed {
      pagesDelegate?.pageViewController(self, setViewController: pages[currentIndex], atPage: currentIndex)
    }
  }
}

// MARK: Private methods

extension PagesController {

  func viewControllerIndex(viewController: UIViewController) -> Int? {
    return find(pages, viewController)
  }

  private func toggle() {
    for recognizer in gestureRecognizers {
      (recognizer as! UIGestureRecognizer).enabled = enableSwipe
    }
  }

  private func addViewController(viewController: UIViewController) {
    pages.append(viewController)

    if pages.count == 1 {
      setViewControllers([viewController],
        direction: .Forward,
        animated: true,
        completion: { [unowned self] finished in
          self.pagesDelegate?.pageViewController(self,
            setViewController: viewController,
            atPage: self.currentIndex)
        })
      if setNavigationTitle {
        title = viewController.title
      }
    }
  }

  private func addConstraints() {
    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: NSLayoutAttribute.Bottom,
      relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom,
      multiplier: 1, constant: -Dimensions.bottomLineBottomMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: NSLayoutAttribute.Left,
      relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Left,
      multiplier: 1, constant: Dimensions.bottomLineSideMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: NSLayoutAttribute.Right,
      relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Right,
      multiplier: 1, constant: -Dimensions.bottomLineSideMargin))

    view.addConstraint(NSLayoutConstraint(item: bottomLineView, attribute: NSLayoutAttribute.Height,
      relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute,
      multiplier: 1, constant: Dimensions.bottomLineHeight))
  }
}

extension Array {

  func at(index: Int?) -> T? {
    if let index = index where index >= 0 && index < endIndex {
      return self[index]
    } else {
      return nil
    }
  }

}

func nextIndex(x: Int?) -> Int? {
  return x.map { $0 + 1 }
}

func prevIndex(x: Int?) -> Int? {
  return x.map { $0 - 1 }
}
