function parser = pcomb_create_empty()

parser = @parse_empty;

    function result = parse_empty(~, position)
        tree = struct( ...
            'symbol', '', ...
            'type', 'terminal', ...
            'value', '' );
        result = struct( ...
            'success', true, ...
            'position', position, ...
            'tree', tree );
    end

end
