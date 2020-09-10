#==============================================================================
# This Pointwise Glyph script creates a complex unstructured domain.
# Author: Ethan Alan Hereth
# Email:  ehereth@utk.edu
#==============================================================================

package require PWI_Glyph

# Set this to zero/false if the script should be quite.
set verbose true

# Record the value of pw::DomainUnstructured InitializeInterior.
set origInitInterior [pw::DomainUnstructured getInitializeInterior]

set startTime [pwu::Time now]

if {[catch {

  # Create selection mask for outer edge. Run script on selected connectors if
  # there are any.
  set outerEdgeMask [pw::Display createSelectionMask -requireConnector Dimensioned]
  pw::Display getSelectedEntities -selectionmask $outerEdgeMask outerConnectors
  set nOuterCons [llength $outerConnectors(Connectors)]

  # There are no pre-selected connectors, ask for them.
  if {$nOuterCons == 0} {
    if {![pw::Display selectEntities -selectionmask $outerEdgeMask \
        -description "Select connectors for outer edge" outerConnectors] } {
      set outerConnectors(Connectors) ""
    }

    set nOuterCons [llength $outerConnectors(Connectors)]

    if {$nOuterCons == 0} {
      puts "No connectors for the outer edge were selected."
      exit
    }
  }

  # Create outer edge from connectors.
  set outerEdge [pw::Edge createFromConnectors $outerConnectors(Connectors)]

  if {![$outerEdge isClosed]} {
    puts "The outer edge must be a closed loop."
    exit
  }

  lappend gEdges $outerEdge

  if {$verbose} {
    puts "Defined outer edge."
  }

  # Create selection mask for connectors to be used for inner edges.
  set innerEdgesMask [pw::Display createSelectionMask -requireConnector Dimensioned]

  if {![pw::Display selectEntities -selectionmask $innerEdgesMask \
      -description "Select connectors for inner edge" \
      -exclude $outerConnectors(Connectors) innerConnectors] } {
    set innerConnectors(Connectors) ""
  }

  set nInnerCons [llength $innerConnectors(Connectors)]

  if {$nInnerCons == 0} {
    puts "No connectors for the inner edges were selected."
    exit
  }

  set createDomStartTime [clock seconds]

  # Create the least amount of edges possible from selected inner connectors.
  set edges [pw::Edge createFromConnectors $innerConnectors(Connectors)]

  # Create an unstructured domain.
  set domain [pw::DomainUnstructured create]

  # Disable domain initialization to speed up domain creation.
  pw::DomainUnstructured setInitializeInterior false

  # Record the original domain shape constraint option.
  set origShapeConstraint [$domain getUnstructuredSolverAttribute ShapeConstraint]

  # Turn off any shape constraints which may cause isValid to fail for the
  # wrong reason.
  $domain setUnstructuredSolverAttribute ShapeConstraint Free

  # Modify domain using a modification mode. All changes happen to a copy of
  # the domain, improving performance.
  set modMode [pw::Application begin Modify $domain]

  set inValidCnt 0
  set validCnt 0

  # Loop over each edge.
  foreach edge $edges {

    $domain addEdge $outerEdge

    # Check if the edge is closed (loop) or open (baffle).
    if {![$edge isClosed]} {

      # If the edge is open, add the connectors to the edge a second time in
      # reverse order. This will be a baffle.
      set edgeCons ""
      for {set i 1} {$i <= [$edge getConnectorCount]} {incr i} {
        lappend edgeCons [$edge getConnector $i]
      }

      # Add connectors to the edge in the reverse order.
      for {set i [expr {[llength $edgeCons] - 1}]} {$i >= 0} {incr i -1} {
        $edge addConnector [lindex $edgeCons $i]
      }
    }

    # If the edge is closed, add it to the domain.
    $domain addEdge $edge

    # Check if the domain has a valid edge definition. If it does not, reverse
    # the edge.
    if {![$domain isValid]} {
      $edge reverse
      incr inValidCnt
    } else {
      incr validCnt
    }

    lappend gEdges $edge

    if {$verbose && ([llength $gEdges] % 100) == 0} {
      puts "processed [llength $gEdges] internal edges"
    }

    # Remove all edges to speed up isValid computation; the outer edge gets
    # re-added at the beginning of the loop.
    $domain removeEdges -preserve
  }

  set endTime [clock seconds]

  set nEdges [llength $gEdges]

  if {$verbose} {
    puts "processed [expr $nEdges - 1] internal edges (took [pwu::Time elapsed $createDomStartTime] seconds)"
    puts ""
    puts "Complete edge validation..."
    puts "    $inValidCnt edges reversed..."
    puts "    $validCnt edges ok..."

    puts "Creating final domain..."
  }

  $domain setName "GlyphDomain"

  foreach edge $gEdges {
    $domain addEdge $edge
  }

  if {$verbose} {
    puts "Created domain [$domain getName]"
  }

} retValue] == 1} {
  # Something went wrong, abort the modification mode in order to die cleanly.
  puts "Script failed with message: $retValue"

  # Reset InitializeInterior.
  pw::DomainUnstructured setInitializeInterior $origInitInterior

  # Reset ShapeConstraint
  $domain setUnstructuredSolverAttribute ShapeConstraint $origShapeConstraint

  # Abort modification mode.
  $modMode abort

  exit
} else {
  # End the modification mode to apply changes.
  $modMode end

  # Reset InitializeInterior.
  pw::DomainUnstructured setInitializeInterior $origInitInterior

  # Reset ShapeConstraint
  $domain setUnstructuredSolverAttribute ShapeConstraint $origShapeConstraint

  if {$verbose} {
    puts "Total elapsed time is [pwu::Time elapsed $startTime] seconds"
  }

  exit
}
# vim:filetype=tcl
