//
//  MyMoviesTableViewController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import CoreData

class MyMoviesTableViewController: UITableViewController {
    
    let movieController = MovieController()
    
    // MARK: - Properties
      
      lazy var fetchedResultsController: NSFetchedResultsController<Movie> = {
          let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
          fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true),
                                         NSSortDescriptor(key: "hasWatched", ascending: true)]
          
          let context = CoreDataStack.shared.mainContext
          let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "hasWatched", cacheName: nil)
          
          frc.delegate = self
          
          do {
              try frc.performFetch()
          } catch {
              NSLog("Error performing initial fetch inside fetchedResultsController: \(error)")
          }
          return frc
      }()
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.delegate = self
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return fetchedResultsController.sections?.count ?? 1
        
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.reuseIdentifier, for: indexPath) as? MovieTableViewCell else {
            fatalError("Can't dequeue cell of type \(MovieTableViewCell.reuseIdentifier)")
        }
        

        cell.movie = fetchedResultsController.object(at: indexPath)
        cell.movieController = self.movieController
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionTitle = fetchedResultsController.sections?[section] else { return nil }
        
        if sectionTitle.name == "0" {
            return "Not Seen"
        } else {
            return "Seen"
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let movie = fetchedResultsController.object(at: indexPath)
                movieController.deleteMovieFromServer(movie) { (result) in
                    guard let _ = try? result.get() else { return }
                    DispatchQueue.main.async {
                        let moc = CoreDataStack.shared.mainContext
                        moc.delete(movie)
                        do {
                            try moc.save()
                            tableView.reloadData()
                        } catch {
                            NSLog("Error saving managed object context: \(error)")
                            moc.reset()
                        }
                    }
                }
            }
        }
        
    }
  

  


extension MyMoviesTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
    
}

