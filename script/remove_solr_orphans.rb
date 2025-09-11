# To run this script: bundle exec rails runner script/remove_solr_orphans.rb
#
# Ths script removes Solr entries for Notebook records that no longer exist in the database

def find_solr_orphans
    solr_ids = []
    page = 1
    per_page = 20

    begin
        loop do
            search_results = Notebook.search do
                paginate page: page, per_page: per_page
            end
            current_ids = search_results.hits.map(&:primary_key).map(&:to_i)
            break if current_ids.empty?
            solr_ids.concat(current_ids)
            puts "Collected #{solr_ids.size} Solr IDs so far on page #{page}"
            page += 1
        end
    rescue => e
        puts "failed to get Solr IDs #{e}"
        return []
    end
    puts "Total Solr IDs collected #{solr_ids.size}"
    db_ids = Notebook.pluck(:id)
    puts "Total DB IDs collected #{db_ids.size}"
    orphan_ids = solr_ids - db_ids
    puts "Total Orphaned Solr IDs found: #{orphan_ids.size}"
    orphan_ids
end

def confirm?
    puts "Are you sure you want to proceed with removing orphaned Solr entries (yes/no)"
    answer = $stdin.gets.chomp.downcase
    answer == 'yes' || answer == 'y'
end

def remove_solr_orphans
    puts "Starting orphaned Solr entries removal process..."
    orphan_ids = find_solr_orphans()
    if orphan_ids.empty?
        puts "No orphaned Solr entries found."
        return
    end
    puts "The following orphaned Solr entries will be removed from Solr:"
    results = Sunspot.search(Notebook) do
        with(:id, orphan_ids)
        paginate page: 1, per_page: orphan_ids.size
    end
    results.hits.each do |hit|
        puts "ID: #{hit.primary_key}"
        puts "Title: #{hit.stored(:title)}"
        puts "Description: #{hit.stored(:description)}"
        puts "-" * 40
    end
    unless confirm?
        puts "Operation cancelled by user."
        return
    end
    orphan_ids.each do |id|
        Sunspot.remove_by_id(Notebook, id)
        puts "Removed orphaned Solr entry for Notebook ID: #{id}"
    end
    Sunspot.commit
    puts "Orphaned Solr entries removal process completed."
end

remove_solr_orphans()
