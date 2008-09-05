class DownloadsController < ApplicationController

  def show
    if params[:document][:type].constantize.equal?(Document)
      @document = params[:document][:type].constantize.find(params[:document][:id])
      unless params[:document][:last] == 'true'
        send_file("documents/#{@document.owner_class}/#{@document.file_type_id}/#{@document.id}.#{@document.extension}")
      else
        send_file("documents/#{@document.owner_class}/#{@document.file_type_id}/#{@document.id}/#{@document.document_versions.size}.#{@document.extension}")
      end
     
    elsif params[:document][:type].constantize.equal?(DocumentVersion)
      @document_version = params[:document][:type].constantize.find(params[:document][:id])
      send_file("documents/#{@document.document.owner_class}/#{@document.document.file_type_id}/#{@document.document.id}/#{@document.version}.#{@document.document.extension}")      
    end

    #FIXME Vérification des permissions sur le fichier et si le fichier existe ou pas
  end

end
