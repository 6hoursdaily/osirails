/* This method permit to return selected option value for a select */
function selectedValue(select) {
    return select.options[select.selectedIndex].value;
}

/* This method permit to refresh categories select and this dependence */
function refreshCategories(select, max_level, value) {
    
    position = select.id.lastIndexOf("_");
    select_id = select.id.substr(position + 1);
    next_select = parseInt(select_id) + 1
    
    id = selectedValue(select);
    
    document.getElementById('product_informations').style.display = 'none';
    document.getElementById('product_reference_informations').style.display = 'none';

    
    if (id != 0){
        
        new Ajax.Request('/product_reference_categories/'+id+'/product_reference_categories',
            {
                method: 'get',
                onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'},
                onSuccess: function(transport){
                    response = transport.responseText
                    
                    document.getElementById('select_'+next_select).innerHTML = response;
                    if (select_id < max_level) {
                        value += 1
                        refreshCategories(document.getElementById('select_'+next_select), max_level, value);
                    }
                }
            }
        )
        
        if (value == 0) {
            new Ajax.Request('/product_reference_categories/'+id+'/product_references',
                {
                    method: 'get',
                    onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'},
                    onSuccess: function(transport){
                        response = transport.responseText
                        select_ref = document.getElementById('select_reference');
                        select_ref.innerHTML = response;
                        refreshProductsList(select_ref, id, 0);
                    }
                }
            )            
        }
        
    }
    if (id == 0 && value != 1){
        select_list = ""
        for (i = 1; i < select.options.length ; i ++) {
            if ( i != (select.options.length - 1) ) {
                select_list += select.options[i].value+',';
            }
            else {
                select_list += select.options[i].value;
            }
        }
        
        
        new Ajax.Request('/product_reference_categories/'+select_list+'/product_reference_categories',
            {
                method: 'get',
                onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'},
                onSuccess: function(transport){
                    response = transport.responseText
                    document.getElementById('select_'+next_select).innerHTML = response;
                    if (select_id < max_level) {
                        value += 1
                        refreshCategories(document.getElementById('select_'+next_select), max_level, value);
                    }
                }
            }
        )
        if (value == 0){
            new Ajax.Request('/product_reference_categories/'+select_list+'/product_references',
                {
                    method: 'get',
                    onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'},
                    onSuccess: function(transport){
                        response = transport.responseText
                        select_ref = document.getElementById('select_reference');
                        select_ref.innerHTML = response;
                        refreshProductsList(select, select_list, 0);
                    }
                }
            )
        }
    }
    
}

/* This method permit to refresh reference information and this dependence */
function refreshReferenceInformation(select) {
    id = selectedValue(select);
    
    if (id != 0) {
        new Ajax.Request('/product_references/'+id,
            {
                method: 'get',
                onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'}, onComplete: function() {document.getElementById('catalog_loading').style.visibility = 'hidden'},
                onSuccess: function(transport){
                    response = transport.responseText
                    
                    document.getElementById('product_informations').style.display = 'none';
                    document.getElementById('product_reference_informations').style.display = 'block';
                    document.getElementById('product_reference_informations').innerHTML = response;
                    refreshProductsList(select, id, 1);
                }
            }
        )   
    }
    else if (id == 0){
        select_list = ""
        refreshProductsList(select, id, 1);
        document.getElementById('product_informations').style.display = 'none';
        document.getElementById('product_reference_informations').style.display = 'none';
    }
    else {
        document.getElementById('products_list').style.display = 'none';
        document.getElementById('product_informations').style.display = 'none';
        document.getElementById('product_reference_informations').style.display = 'none';
    }
    
}

/* This method permit to refresh products table */
function refreshProductsList(select, id, value) {
    
    if (value == 0) {
        select_ref = document.getElementById('select_reference')
        
        select_ref_list = ""
        for (i = 1; i < select_ref.options.length ; i++) {
            if (i != (select_ref.options.length -1)) {
                select_ref_list += select_ref.options[i].value+',';
            }
            else {
                select_ref_list += select_ref.options[i].value;
            }
        }
        
        select_list = ""
        for (i = 1; i < select.options.length ; i ++) {
            if ( i != (select.options.length - 1) ) {
                select_list += select.options[i].value+',';
            }
            else {
                select_list += select.options[i].value;
            }
        }
        url = '/product_reference_categories/'+select_list+'/product_references/'+select_ref_list+'/products/'
    }
    if (value == 1) {
        if (id != 0) {
            select_list = selectedValue(select);
        }
        else if (id == 0) {
            for (i = 1; i < select.options.length ; i ++) {
                if ( i != (select.options.length - 1) ) {
                    select_list += select.options[i].value+',';
                }
                else {
                    select_list += select.options[i].value;
                }
            }       
        }    
        url = '/product_references/'+select_list+'/products/'      
    }
    if (select_list != "" || select_ref_list != ""){
        new Ajax.Request(url,
            {
                method: 'get',
                onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'},
                onComplete: function() {document.getElementById('catalog_loading').style.visibility = 'hidden'},
                onSuccess: function(transport){
                    response = transport.responseText
                    document.getElementById('products_list').style.display = 'block';
                    document.getElementById('products_list').innerHTML = response;
                }
            }
        )
    }
    else {
        document.getElementById('products_list').style.display = 'none';
        document.getElementById('catalog_loading').style.visibility = 'hidden';
    }
}

/* This method permit to refresh product information */
function refreshProduct(element){
    position = element.id.lastIndexOf("_");
    id = element.id.substr(position + 1);
    
    document.getElementById('product_informations').style.display = 'block';
    
    new Ajax.Request('/products/'+id,
        {
            method: 'get',
            onLoading: function() {document.getElementById('catalog_loading').style.visibility = 'visible'}, onComplete: function() {document.getElementById('catalog_loading').style.visibility = 'hidden'},
            onSuccess: function(transport){
                response = transport.responseText
                document.getElementById('product_informations').innerHTML = response;
            }
        }
    )
}
